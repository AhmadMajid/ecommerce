class ShippingMethod < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }
  validates :base_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_per_kg, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :min_delivery_days, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 365 }
  validates :max_delivery_days, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 365 }
  validates :carrier, presence: true, length: { maximum: 50 }

  # Custom validation
  validate :max_delivery_days_greater_than_min

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_delivery_time, -> { order(:min_delivery_days, :max_delivery_days) }
  scope :by_cost, -> { order(:base_cost) }
  scope :by_sort_order, -> { order(:sort_order, :name) }

  # Instance methods
  def delivery_estimate
    if min_delivery_days == max_delivery_days
      "#{min_delivery_days} business #{'day'.pluralize(min_delivery_days)}"
    else
      "#{min_delivery_days}-#{max_delivery_days} business days"
    end
  end

  def calculate_cost(weight_kg = 0, cart_total = 0)
    return 0.0 if free_shipping_threshold.present? && cart_total >= free_shipping_threshold

    cost = base_cost
    cost += (cost_per_kg * weight_kg) if cost_per_kg.present? && weight_kg > 0
    cost.round(2)
  end

  def formatted_base_cost
    ActionController::Base.helpers.number_to_currency(base_cost)
  end

  def display_name_with_time
    "#{name} (#{delivery_estimate})"
  end

  def free_shipping_eligible?(cart_total)
    free_shipping_threshold.present? && cart_total >= free_shipping_threshold
  end

  private

  def max_delivery_days_greater_than_min
    return unless min_delivery_days.present? && max_delivery_days.present?

    if max_delivery_days < min_delivery_days
      errors.add(:max_delivery_days, "must be greater than or equal to minimum delivery days")
    end
  end
end
