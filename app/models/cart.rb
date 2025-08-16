class Cart < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :coupon, optional: true
  has_many :cart_items, dependent: :destroy
  alias_method :items, :cart_items  # Alias for easier access
  has_many :products, through: :cart_items
  has_one :checkout, dependent: :destroy

  # Enums
  enum :status, {
    active: 0,
    abandoned: 1,
    converted: 2
  }

  # Validations
  validates :currency, presence: true, length: { is: 3 }
  validates :subtotal, :tax_amount, :shipping_amount, :discount_amount, :total,
            numericality: { greater_than_or_equal_to: 0 }
  validates :session_id, presence: true, if: :guest_cart?

  # Scopes
  scope :guest_carts, -> { where(user_id: nil) }
  scope :user_carts, -> { where.not(user_id: nil) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }

  # Callbacks
  before_save :calculate_totals
  before_create :set_expiry_date

  # Instance methods
  def guest_cart?
    user_id.nil?
  end

  def empty?
    cart_items.empty?
  end

  def item_count
    cart_items.sum(:quantity)
  end

  def unique_item_count
    cart_items.count
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def add_product(product, quantity = 1, options = {})
    existing_item = cart_items.find_by(product: product)

    if existing_item
      existing_item.quantity += quantity
      existing_item.save!
    else
      cart_items.create!(
        product: product,
        quantity: quantity,
        price: product.price,
        product_name: product.name
      )
    end
  end

  def update_item_quantity(product, quantity)
    item = cart_items.find_by(product: product)
    return false unless item

    if quantity <= 0
      item.destroy
    else
      item.update(quantity: quantity)
    end
  end

  def remove_product(product)
    cart_items.find_by(product: product)&.destroy
  end

  def clear!
    cart_items.destroy_all
    update_totals!
  end

  def merge_with!(other_cart)
    return unless other_cart && other_cart != self

    other_cart.cart_items.each do |item|
      existing_item = cart_items.find_by(product: item.product)

      if existing_item
        existing_item.quantity += item.quantity
        existing_item.save!
      else
        item.update!(cart: self)
      end
    end

    other_cart.destroy
    recalculate_totals!
  end

  def add_item(product, variant: nil, quantity: 1, custom_attributes: nil)
    existing_item = find_existing_item(product, variant)

    if existing_item
      existing_item.update!(quantity: existing_item.quantity + quantity.to_i)
      existing_item
    else
      create_new_item(product, variant, quantity, custom_attributes)
    end
  end

  def remove_item(cart_item)
    cart_item.destroy
    recalculate_totals!
  end

  def update_item_quantity(cart_item, new_quantity)
    if new_quantity.to_i <= 0
      remove_item(cart_item)
    else
      cart_item.update!(quantity: new_quantity.to_i)
      recalculate_totals!
    end
  end

  def clear_items
    cart_items.destroy_all
    recalculate_totals!
  end

  def apply_coupon(coupon_code)
    return { success: false, message: "Coupon code cannot be blank" } if coupon_code.blank?

    found_coupon = Coupon.find_by(code: coupon_code.upcase.strip)

    unless found_coupon
      return { success: false, message: "Invalid coupon code" }
    end

    unless found_coupon.valid_for_cart?(self)
      if found_coupon.expired?
        return { success: false, message: "This coupon has expired" }
      elsif found_coupon.not_started?
        return { success: false, message: "This coupon is not yet valid" }
      elsif found_coupon.usage_exceeded?
        return { success: false, message: "This coupon has reached its usage limit" }
      elsif found_coupon.below_minimum_order?(self)
        return { success: false, message: "Order must be at least #{ApplicationController.helpers.number_to_currency(found_coupon.min_order_amount)} to use this coupon" }
      else
        return { success: false, message: "This coupon cannot be applied to your cart" }
      end
    end

    self.coupon = found_coupon
    self.coupon_code = found_coupon.code
    recalculate_totals!

    { success: true, message: "Coupon applied successfully! You saved #{ApplicationController.helpers.number_to_currency(discount_amount)}" }
  end

  def remove_coupon
    self.coupon = nil
    self.coupon_code = nil
    recalculate_totals!
    { success: true, message: "Coupon removed" }
  end

  def convert_to_order!
    update!(status: 'converted')
  end

  def abandon!
    update!(status: 'abandoned')
  end

  def merge_with(other_cart)
    return if other_cart == self

    other_cart.cart_items.each do |item|
      add_item(item.product, variant: item.product_variant,
               quantity: item.quantity, custom_attributes: item.custom_attributes)
    end

    other_cart.destroy
    recalculate_totals!
  end

  def has_physical_products?
    cart_items.joins(:product).where(products: { requires_shipping: true }).exists?
  end

  def total_weight
    cart_items.includes(:product, :product_variant).sum do |item|
      weight = item.product_variant&.effective_weight || item.product.weight || 0
      weight * item.quantity
    end
  end

  def total_price
    total
  end

  def recalculate_totals!
    calculate_totals
    save!
  end

  def update_totals!
    recalculate_totals!
  end

  # Tax calculation - 8% standard rate
  def calculate_tax_rate
    0.08
  end

  # Shipping calculation based on cart total
  def calculate_shipping_cost
    return 0.0 unless has_physical_products?

    if subtotal >= 100
      0.0  # Free shipping over $100
    elsif subtotal >= 50
      5.0  # Reduced shipping over $50
    else
      10.0 # Standard shipping
    end
  end

  private

  def calculate_totals
    self.subtotal = cart_items.sum { |item| item.quantity * item.price }
    calculate_tax_amount
    calculate_shipping_amount
    calculate_discount_amount
    self.total = subtotal + tax_amount + shipping_amount - discount_amount
  end

  def calculate_tax_amount
    tax_rate = calculate_tax_rate
    taxable_amount = cart_items.joins(:product).where(products: { taxable: true }).sum { |item| item.quantity * item.price }
    self.tax_amount = (taxable_amount * tax_rate).round(2)
  end

  def calculate_shipping_amount
    self.shipping_amount = calculate_shipping_cost
  end

  def calculate_discount_amount
    if coupon.present?
      self.discount_amount = coupon.calculate_discount(subtotal)
    elsif coupon_code.present?
      # Fallback for legacy hardcoded coupons
      case coupon_code.downcase
      when 'save10'
        self.discount_amount = [(subtotal * 0.10).round(2), 50.0].min
      when 'save20'
        self.discount_amount = [(subtotal * 0.20).round(2), 100.0].min
      when 'freeship'
        self.discount_amount = shipping_amount
      else
        self.discount_amount = 0
      end
    else
      self.discount_amount = 0
    end
  end

  def has_physical_products?
    cart_items.joins(:product).where(products: { requires_shipping: true }).exists?
  end

  def set_expiry_date
    self.expires_at = user_id.present? ? 30.days.from_now : 7.days.from_now
  end
end
