class Category < ApplicationRecord
  # Associations
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id', dependent: :destroy
  has_many :products, dependent: :destroy

  # Active Storage
  has_one_attached :image
  has_one_attached :banner_image

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :meta_title, length: { maximum: 60 }, allow_blank: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Custom validations
  validate :cannot_be_parent_of_itself
  validate :parent_must_be_active_if_child_is_active

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :featured, -> { where(featured: true) }
  scope :root_categories, -> { where(parent_id: nil) }
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }
  scope :with_products, -> { joins(:products).distinct }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?
  before_validation :set_meta_title, if: :name_changed?

  # Instance methods
  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def has_children?
    children.any?
  end

  def ancestors
    return [] if root?

    ancestors_array = []
    current_category = parent

    while current_category
      ancestors_array.unshift(current_category)
      current_category = current_category.parent
    end

    ancestors_array
  end

  def descendants
    descendants_array = []

    children.each do |child|
      descendants_array << child
      descendants_array.concat(child.descendants)
    end

    descendants_array
  end

  def descendant_ids
    descendants.pluck(:id)
  end

  def level
    ancestors.count
  end

  def breadcrumb_names
    (ancestors + [self]).map(&:name)
  end

  def breadcrumbs
    ancestors + [self]
  end

  def breadcrumb_path
    breadcrumb_names.join(' > ')
  end

  def all_products
    if leaf?
      products
    else
      descendant_ids = descendants.pluck(:id)
      Product.where(category_id: [id] + descendant_ids)
    end
  end

  def products_count(include_descendants: false)
    if include_descendants
      descendant_ids = descendants.pluck(:id)
      Product.where(category_id: [id] + descendant_ids).count
    else
      products.count
    end
  end

  def active_products_count(include_descendants: false)
    if include_descendants
      descendant_ids = descendants.pluck(:id)
      Product.active.where(category_id: [id] + descendant_ids).count
    else
      products.active.count
    end
  end

  def product_count
    active_products_count(include_descendants: true)
  end

  def breadcrumb_trail
    ancestors.reverse + [self]
  end

  def to_param
    slug
  end

  def display_name
    root? ? name : "#{breadcrumb_path}"
  end

  def can_be_deleted?
    products.empty? && children.empty?
  end

  private

  def generate_slug
    return if name.blank?

    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1

    while Category.where(slug: slug_candidate).where.not(id: id).exists?
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def set_meta_title
    self.meta_title = name if meta_title.blank? && name.present?
  end

  def cannot_be_parent_of_itself
    return unless parent_id.present?

    if id == parent_id
      errors.add(:parent_id, "cannot be the same as the category itself")
    elsif ancestors.include?(self)
      errors.add(:parent_id, "would create a circular reference")
    end
  end

  def parent_must_be_active_if_child_is_active
    return unless parent&.present? && active?

    unless parent.active?
      errors.add(:active, "cannot be true when parent category is inactive")
    end
  end
end
