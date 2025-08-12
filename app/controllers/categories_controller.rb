class CategoriesController < ApplicationController
  before_action :set_category, only: [:show]

  def index
    @categories = Category.active.roots.includes(:children, image_attachment: :blob)
      .order(:position, :name)
  end

  def show
    @products = Product.active.includes(:category, images_attachments: :blob)
    @categories = Category.active.includes(:parent)

    # Include products from subcategories
    category_ids = [@category.id] + @category.descendant_ids
    @products = @products.where(category_id: category_ids)

    # Search within category
    if params[:search].present?
      @products = @products.where("name ILIKE ? OR description ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Price range filtering
    if params[:min_price].present?
      @products = @products.where("price >= ?", params[:min_price])
    end

    if params[:max_price].present?
      @products = @products.where("price <= ?", params[:max_price])
    end

    # Sorting
    case params[:sort]
    when 'price_low'
      @products = @products.order(:price)
    when 'price_high'
      @products = @products.order(price: :desc)
    when 'name'
      @products = @products.order(:name)
    when 'newest'
      @products = @products.order(created_at: :desc)
    when 'featured'
      @products = @products.order(featured: :desc, created_at: :desc)
    else
      @products = @products.order(featured: :desc, created_at: :desc)
    end

    # Pagination
    @products = @products.page(params[:page]).per(24)

    # Subcategories for navigation
    @subcategories = @category.children.active.includes(image_attachment: :blob)
      .order(:position, :name)

    # For AJAX requests
    if request.xhr?
      render partial: 'products/products_grid', locals: { products: @products }
    end
  end

  private

  def set_category
    @category = Category.active.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
