class Product < ApplicationRecord
  include PgSearch::Model

  # Associations
  belongs_to :category
  has_many :product_variants, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy

  # Active Storage
  has_many_attached :images

  # Enums - temporarily disabled
  # enum :weight_unit, {
  #   kg: 'kg',
  #   lb: 'lb',
  #   g: 'g',
  #   oz: 'oz'
  # }

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :short_description, length: { maximum: 500 }, allow_blank: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :compare_at_price, numericality: { greater_than: 0 }, allow_blank: true
  validates :cost_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :sku, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :weight, numericality: { greater_than: 0 }, allow_blank: true
  validates :length, :width, :height, numericality: { greater_than: 0 }, allow_blank: true
  validates :inventory_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :meta_title, length: { maximum: 60 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :meta_keywords, length: { maximum: 255 }, allow_blank: true

  # Custom validations
  validate :compare_at_price_must_be_greater_than_price
  validate :published_at_cannot_be_future_date

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :featured, -> { where(featured: true) }
  scope :published, -> { where('published_at IS NOT NULL AND published_at <= ?', Time.current) }
  scope :available, -> { active.published }
  scope :in_stock, -> { where('inventory_quantity > 0 OR track_inventory = false OR allow_backorders = true') }
  scope :low_stock, -> { where('inventory_quantity <= low_stock_threshold AND track_inventory = true') }
  scope :out_of_stock, -> { where('inventory_quantity = 0 AND track_inventory = true AND allow_backorders = false') }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:name) }
  scope :recent, -> { order(created_at: :desc) }
  scope :price_range, ->(min, max) { where(price: min..max) }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?
  before_validation :set_meta_title, if: :name_changed?
  before_validation :set_sku, if: :new_record?
  before_save :set_published_at, if: :active_changed?
  scope :by_category, ->(category) { where(category: category) }
  scope :by_vendor, ->(vendor) { where(vendor: vendor) }
  scope :by_product_type, ->(product_type) { where(product_type: product_type) }
  scope :price_range, ->(min, max) { where(price: min..max) }
  scope :ordered, -> { order(:sort_order, :name) }

  # Search configuration
  pg_search_scope :search_products,
    against: [:name, :description, :short_description, :sku, :vendor, :product_type],
    associated_against: {
      category: [:name, :description]
    },
    using: {
      tsearch: { prefix: true, any_word: true },
      trigram: { threshold: 0.3 }
    }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?
  before_save :set_meta_title, if: :name_changed?
  before_save :calculate_profit_margin
  after_update :update_variant_pricing, if: :price_changed?

  # Instance methods
  def available?
    active? && published?
  end

  def published?
    published_at.nil? || published_at <= Time.current
  end

  def in_stock?
    !track_inventory || inventory_quantity > 0 || allow_backorders
  end

  def low_stock?
    track_inventory && inventory_quantity <= low_stock_threshold
  end

  def out_of_stock?
    track_inventory && inventory_quantity <= 0 && !allow_backorders
  end

  def stock_status
    return 'unlimited' unless track_inventory
    return 'out_of_stock' if out_of_stock?
    return 'low_stock' if low_stock?
    'in_stock'
  end

  def can_be_purchased?
    available? && in_stock?
  end

  def on_sale?
    compare_at_price.present? && compare_at_price > price
  end

  def sale_percentage
    return 0 unless on_sale?
    ((compare_at_price - price) / compare_at_price * 100).round
  end

  def profit_margin_percentage
    return 0 if cost_price.blank? || cost_price.zero?
    ((price - cost_price) / price * 100).round(2)
  end

  def primary_image
    images.attached? ? images.first : nil
  end

  def has_images?
    images.attached?
  end

  def dimensions
    return nil unless length.present? && width.present? && height.present?
    "#{length} × #{width} × #{height}"
  end

  def formatted_weight
    return nil unless weight.present?
    "#{weight} #{weight_unit || 'kg'}"
  end

  def to_param
    slug
  end

  def decrease_inventory!(quantity)
    return unless track_inventory
    update!(inventory_quantity: [inventory_quantity - quantity, 0].max)
  end

  def increase_inventory!(quantity)
    return unless track_inventory
    update!(inventory_quantity: inventory_quantity + quantity)
  end

  def category_breadcrumb
    category.breadcrumb_path
  end

  def related_products(limit: 4)
    Product.active
           .where(category: category)
           .where.not(id: id)
           .limit(limit)
  end

  def can_be_deleted?
    !cart_items.exists? && !order_items.exists?
  end

  def thumbnail(size = [300, 300])
    primary_image&.variant(resize_to_limit: size) if primary_image
  end

  def has_variants?
    product_variants.any?
  end

  def default_variant
    product_variants.first
  end

  private

  def generate_slug
    return if name.blank?

    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1

    while Product.where(slug: slug_candidate).where.not(id: id).exists?
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def set_meta_title
    self.meta_title = name if meta_title.blank? && name.present?
  end

  def set_sku
    return if sku.present?

    base_sku = name.present? ? name.upcase.gsub(/[^A-Z0-9]/, '')[0, 4] : 'PROD'
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    self.sku = "#{base_sku}#{timestamp}"
  end

  def set_published_at
    if active? && published_at.nil?
      self.published_at = Time.current
    elsif !active?
      self.published_at = nil
    end
  end

  def compare_at_price_must_be_greater_than_price
    return unless compare_at_price.present? && price.present?

    if compare_at_price <= price
      errors.add(:compare_at_price, 'must be greater than the regular price')
    end
  end

  def published_at_cannot_be_future_date
    return unless published_at.present?

    if published_at > Time.current
      errors.add(:published_at, 'cannot be in the future')
    end
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end

  def set_meta_title
    self.meta_title = name if meta_title.blank? && name.present?
  end

  def calculate_profit_margin
    # This is calculated in the profit_margin method, but you could store it here if needed
  end

  def update_variant_pricing
    # Update variant pricing if they don't have custom pricing
    product_variants.where(price: nil).update_all(price: price)
  end

  def compare_at_price_greater_than_price
    if compare_at_price.present? && compare_at_price <= price
      errors.add(:compare_at_price, "must be greater than the selling price")
    end
  end

  def available_at_not_in_past
    if available_at.present? && available_at < Time.current && available_at_changed?
      errors.add(:available_at, "cannot be in the past")
    end
  end
end
