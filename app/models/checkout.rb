class Checkout < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :cart
  belongs_to :shipping_method, optional: true
  belongs_to :coupon, optional: true

  # Enums
  enum :status, {
    started: 'started',
    shipping_info: 'shipping_info',
    payment_info: 'payment_info',
    review: 'review',
    completed: 'completed',
    cancelled: 'cancelled'
  }, scopes: false

  # Validations
  validates :session_id, presence: true
  validates :status, presence: true

  # Conditional validations based on checkout step
  with_options if: :shipping_info_step_or_later? do
    validate :shipping_address_present
    validates :shipping_method_id, presence: true
  end

  with_options if: :payment_info_step_or_later? do
    validates :payment_method, presence: true
    validate :billing_address_present
  end

  # Callbacks
  before_create :set_expiry_date
  before_save :calculate_totals

  # Scopes
  scope :active, -> { where.not(status: ['completed', 'cancelled']) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :for_session, ->(session_id) { where(session_id: session_id) }

  # Instance methods
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def guest_checkout?
    user_id.nil?
  end

  def shipping_info_step_or_later?
    !started?
  end

  def payment_info_step_or_later?
    payment_info? || review? || completed?
  end

  def can_proceed_to_payment?
    shipping_info_step_or_later? && shipping_address.present? && shipping_method_id.present?
  end

  def can_proceed_to_review?
    payment_info_step_or_later? && billing_address.present? && payment_method.present?
  end

  def shipping_address_data
    return {} unless shipping_address.present?
    JSON.parse(shipping_address) rescue {}
  end

  def shipping_address_data=(data)
    self.shipping_address = data.to_json
  end

  def billing_address_data
    return {} unless billing_address.present?
    JSON.parse(billing_address) rescue {}
  end

  def billing_address_data=(data)
    self.billing_address = data.to_json
  end

  def same_as_shipping?
    shipping_address_data == billing_address_data
  end

  def formatted_shipping_address
    addr = shipping_address_data
    return '' if addr.empty?

    [
      "#{addr['first_name']} #{addr['last_name']}",
      addr['address_line_1'],
      addr['address_line_2'],
      "#{addr['city']}, #{addr['state_province']} #{addr['postal_code']}",
      addr['country']
    ].compact.reject(&:blank?).join("\n")
  end

  def formatted_billing_address
    addr = billing_address_data
    return '' if addr.empty?

    [
      "#{addr['first_name']} #{addr['last_name']}",
      addr['address_line_1'],
      addr['address_line_2'],
      "#{addr['city']}, #{addr['state_province']} #{addr['postal_code']}",
      addr['country']
    ].compact.reject(&:blank?).join("\n")
  end

  def progress_percentage
    case status
    when 'started' then 25
    when 'shipping_info' then 50
    when 'payment_info' then 75
    when 'review', 'completed' then 100
    else 0
    end
  end

  def next_step
    case status
    when 'started' then 'shipping_info'
    when 'shipping_info' then 'payment_info'
    when 'payment_info' then 'review'
    when 'review' then 'completed'
    else status
    end
  end

  def previous_step
    case status
    when 'payment_info' then 'shipping_info'
    when 'review' then 'payment_info'
    when 'completed' then 'review'
    else 'started'
    end
  end

  def advance_to_next_step!
    return false if completed? || cancelled?

    update!(status: next_step)
  end

  def step_name
    case status
    when 'started' then 'Cart Review'
    when 'shipping_info' then 'Shipping Information'
    when 'payment_info' then 'Payment Information'
    when 'review' then 'Order Review'
    when 'completed' then 'Order Complete'
    else 'Unknown'
    end
  end

  def calculate_totals
    return unless cart

    self.subtotal = cart.subtotal
    self.tax_amount = cart.tax_amount
    self.discount_amount = cart.discount_amount

    # Copy coupon information from cart
    self.coupon_code = cart.coupon_code
    self.coupon_id = cart.coupon_id

    # Calculate shipping amount based on selected shipping method
    if shipping_method.present?
      cart_weight = cart.cart_items.sum { |item| (item.product.weight || 0) * item.quantity }
      self.shipping_amount = shipping_method.calculate_cost(cart_weight, subtotal)
    else
      self.shipping_amount = 0
    end

    self.total_amount = subtotal + tax_amount + shipping_amount - discount_amount
  end

  private

  def shipping_address_present
    if shipping_address.blank? || shipping_address_data.empty?
      errors.add(:shipping_address, "is required")
    end
  end

  def billing_address_present
    if billing_address.blank? || billing_address_data.empty?
      errors.add(:billing_address, "is required")
    end
  end

  def set_expiry_date
    self.expires_at = 2.hours.from_now
  end
end
