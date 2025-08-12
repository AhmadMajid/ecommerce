class CartItem < ApplicationRecord
  # Associations
  belongs_to :cart
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :product_name, presence: true

  # Custom validations
  validate :product_available
  validate :sufficient_inventory

  # Callbacks
  before_validation :set_pricing_details
  before_validation :set_product_details
  after_save :update_cart_totals
  after_destroy :update_cart_totals

  # Instance methods
  def item_name
    product_name
  end

  def item_image
    product.primary_image
  end

  def item_thumbnail(size = [100, 100])
    item_image&.variant(resize_to_limit: size)
  end

  def current_unit_price
    product.price
  end

  def price_changed?
    price != current_unit_price
  end

  def update_pricing!
    self.price = current_unit_price
    save!
  end

  def in_stock?
    product.in_stock?
  end

  def available_quantity
    product.track_inventory ? product.inventory_quantity : 999
  end

  def max_quantity_addable
    if product.track_inventory && !product.allow_backorder
      [product.inventory_quantity - quantity, 0].max
    else
      999 - quantity
    end
  end

  def formatted_options
    return '' if product_options.blank?

    product_options.map { |name, value| "#{name}: #{value}" }.join(', ')
  end

  def discount_amount
    line_discount_amount
  end

  def final_price
    total_price - line_discount_amount
  end

  def total_price
    (price * quantity).round(2)
  end

  private

  def set_pricing_details
    self.price = current_unit_price if price.blank?
  end

  def set_product_details
    self.product_name = product.name if product_name.blank?
  end

  def calculate_total_price
    # This method is kept for backward compatibility but total_price is now calculated dynamically
    total_price
  end

  def update_cart_totals
    cart.recalculate_totals! if cart.persisted?
  end

  def product_available
    unless product&.active?
      errors.add(:product, "is not available")
    end
  end

  def sufficient_inventory
    if product.track_inventory && !product.allow_backorders && product.inventory_quantity < quantity
      errors.add(:quantity, "exceeds available inventory (#{product.inventory_quantity} available)")
    end
  end
end
