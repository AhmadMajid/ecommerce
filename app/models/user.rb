class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable

  # Attribute accessors
  attr_accessor :skip_password_validation

  # Enums
  enum :role, {
    customer: 0,
    admin: 1,
    super_admin: 2
  }, scopes: false

  # Associations
  has_many :addresses, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_many :wishlist_products, through: :wishlists, source: :product
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy

  # Helper methods for default addresses
  has_one :default_billing_address, -> { where(address_type: 'billing', default_address: true) },
          class_name: 'Address'
  has_one :default_shipping_address, -> { where(address_type: 'shipping', default_address: true) },
          class_name: 'Address'

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :phone, format: { with: /\A[\+]?[1-9][\d\s\-\(\)]{7,15}\z/, message: "Invalid phone format" },
            allow_blank: true
  validates :role, presence: true
  validates :date_of_birth, presence: true,
            inclusion: { in: 160.years.ago..18.years.ago, message: "Must be at least 18 years old and not more than 160 years ago" },
            allow_blank: true
  validates :email_notifications, inclusion: { in: [true, false] }
  validates :marketing_emails, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :customers, -> { where(role: 'customer') }
  scope :admins, -> { where(role: ['admin', 'super_admin']) }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin?
    role.in?(%w[admin super_admin])
  end

  def active_cart
    carts.active.first || carts.create(status: 'active')
  end

  # def total_orders
  #   orders.count
  # end

  # def total_spent
  #   orders.where.not(status: ['cancelled', 'refunded']).sum(:total)
  # end

  private

  def password_required?
    return false if skip_password_validation
    super
  end
end
