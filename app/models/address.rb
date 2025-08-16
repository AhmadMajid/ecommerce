class Address < ApplicationRecord
  # Associations
  belongs_to :user

  # Enums
  enum :address_type, {
    billing: 'billing',
    shipping: 'shipping'
  }

  # Validations
  validates :address_type, presence: true
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :company, length: { maximum: 100 }, allow_blank: true
  validates :address_line_1, presence: true, length: { maximum: 255 }
  validates :address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :state_province, presence: true, length: { maximum: 100 }
  validates :postal_code, presence: true, length: { maximum: 20 }
  validates :country, presence: true, length: { is: 2 } # ISO country code
  validates :phone, format: { with: /\A[\+]?[1-9][\d\s\-\(\)]{7,15}\z/, message: "Invalid phone format" },
            allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :billing, -> { where(address_type: 'billing') }
  scope :shipping, -> { where(address_type: 'shipping') }
  scope :default, -> { where(default_address: true) }

  # Callbacks
  before_save :ensure_only_one_default_per_type

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def country_name
    case country
    when 'US' then 'United States'
    when 'CA' then 'Canada'
    when 'GB' then 'United Kingdom'
    when 'AU' then 'Australia'
    when 'DE' then 'Germany'
    when 'FR' then 'France'
    when 'JP' then 'Japan'
    when 'BR' then 'Brazil'
    when 'MX' then 'Mexico'
    when 'IN' then 'India'
    else country
    end
  end

  def single_line_address
    [address_line_1, address_line_2, city, state_province, postal_code, country_name].compact.join(', ')
  end

  def formatted_address
    lines = [full_name]
    lines << company if company.present?
    lines << address_line_1
    lines << address_line_2 if address_line_2.present?
    lines << "#{city}, #{state_province} #{postal_code}"
    lines << country_name
    lines.join("\n")
  end

  def set_as_default!
    Address.transaction do
      # Remove default from other addresses of the same type
      Address.where(user: user, address_type: address_type, default_address: true)
             .where.not(id: id)
             .update_all(default_address: false)

      # Set this address as default
      update!(default_address: true)
    end
  end

  private

  def ensure_only_one_default_per_type
    if default_address? && default_address_changed?
      Address.where(user: user, address_type: address_type, default_address: true)
             .where.not(id: id)
             .update_all(default_address: false)
    end
  end
end
