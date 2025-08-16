class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :cart_items, dependent: :nullify
  has_many :order_items, dependent: :nullify
  
  validates :title, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :inventory_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where('inventory_quantity > 0') }
  
  def available?
    active? && inventory_quantity > 0
  end
  
  def display_name
    "#{product.name} - #{title}"
  end
end