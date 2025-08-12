class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy

  validates :email, presence: true
  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    shipped: 'shipped',
    delivered: 'delivered',
    cancelled: 'cancelled'
  }

  def shipping_address
    return nil unless shipping_address_data.present?
    JSON.parse(shipping_address_data).with_indifferent_access
  end

  def billing_address
    return nil unless billing_address_data.present?
    JSON.parse(billing_address_data).with_indifferent_access
  end
end
