class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :email, presence: true
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

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
