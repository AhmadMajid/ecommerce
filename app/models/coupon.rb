class Coupon < ApplicationRecord
  has_many :carts, dependent: :nullify

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :min_order_amount, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :max_discount_amount, numericality: { greater_than: 0 }, allow_blank: true
  validates :usage_limit, numericality: { greater_than: 0 }, allow_blank: true
  validates :used_count, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :valid_now, -> { where('valid_from IS NULL OR valid_from <= ?', Time.current).where('valid_until IS NULL OR valid_until >= ?', Time.current) }
  scope :available, -> { active.valid_now.where('usage_limit IS NULL OR used_count < usage_limit') }

  before_validation :normalize_code

  def valid_for_cart?(cart)
    return false unless active?
    return false if expired?
    return false if usage_exceeded?
    return false if below_minimum_order?(cart)

    true
  end

  def calculate_discount(subtotal)
    case discount_type
    when 'percentage'
      discount = (subtotal * discount_value / 100).round(2)
      max_discount_amount.present? ? [discount, max_discount_amount].min : discount
    when 'fixed'
      [discount_value, subtotal].min
    else
      0
    end
  end

  def percentage?
    discount_type == 'percentage'
  end

  def fixed?
    discount_type == 'fixed'
  end

  def expired?
    return false if valid_until.nil?
    valid_until < Time.current
  end

  def not_started?
    return false if valid_from.nil?
    valid_from > Time.current
  end

  def usage_exceeded?
    return false if usage_limit.nil?
    used_count >= usage_limit
  end

  def below_minimum_order?(cart)
    return false if min_order_amount.nil? || min_order_amount.zero?
    cart.subtotal < min_order_amount
  end

  def increment_usage!
    increment!(:used_count)
  end

  def display_discount
    if percentage?
      "#{discount_value.to_i}% off"
    else
      "$#{discount_value} off"
    end
  end

  private

  def normalize_code
    self.code = code&.upcase&.strip
  end
end
