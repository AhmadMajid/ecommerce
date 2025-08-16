class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  # Validations
  validates :email, presence: true
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :generate_order_number, on: :create

  # Enums
  enum :status, {
    pending: 0,
    confirmed: 1,
    processing: 2,
    shipped: 3,
    delivered: 4,
    cancelled: 5,
    refunded: 6
  }

  enum :payment_status, {
    payment_pending: 0,
    paid: 1,
    partially_paid: 2,
    payment_refunded: 3,
    partially_refunded: 4
  }, prefix: :payment

  enum :fulfillment_status, {
    unfulfilled: 0,
    partial: 1,
    fulfilled: 2
  }, prefix: :fulfillment

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  # Instance Methods
  def total_in_cents
    (total * 100).to_i
  end

  def stripe_customer
    return nil unless stripe_customer_id
    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def payment_intent
    return nil unless stripe_payment_intent_id
    @payment_intent ||= Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
  end

  def can_be_cancelled?
    pending? || confirmed?
  end

  def can_be_refunded?
    paid? && (confirmed? || processing? || shipped?)
  end

  private

  def generate_order_number
    return if order_number.present?
    
    loop do
      # Generate format: ORD-YYYYMMDD-XXXXX
      date_part = Date.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(2).upcase
      candidate = "ORD-#{date_part}-#{random_part}"
      
      unless Order.exists?(order_number: candidate)
        self.order_number = candidate
        break
      end
    end
  end

  def shipping_address
    {
      first_name: shipping_first_name,
      last_name: shipping_last_name,
      company: shipping_company,
      address_line_1: shipping_address_line_1,
      address_line_2: shipping_address_line_2,
      city: shipping_city,
      state_province: shipping_state_province,
      postal_code: shipping_postal_code,
      country: shipping_country,
      phone: shipping_phone
    }.compact
  end

  def billing_address
    {
      first_name: billing_first_name,
      last_name: billing_last_name,
      company: billing_company,
      address_line_1: billing_address_line_1,
      address_line_2: billing_address_line_2,
      city: billing_city,
      state_province: billing_state_province,
      postal_code: billing_postal_code,
      country: billing_country,
      phone: billing_phone
    }.compact
  end
end
