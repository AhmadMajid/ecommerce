class ProductsController < ApplicationController
  before_action :set_product, only: [:show]

  def index
    @products = Product.active.includes(:category, images_attachments: :blob)
    @categories = Category.active.includes(:parent)

    # Search functionality
    if params[:search].present?
      @products = @products.where("name ILIKE ? OR description ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Category filtering
    if params[:category_id].present?
      category = Category.find(params[:category_id])
      category_ids = [category.id] + category.descendant_ids
      @products = @products.where(category_id: category_ids)
      @current_category = category
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

    # For AJAX requests, render only the products partial
    if request.xhr?
      render partial: 'products_grid', locals: { products: @products }
    end
  end

  def show
    @related_products = Product.active
      .where(category: @product.category)
      .where.not(id: @product.id)
      .includes(:category, images_attachments: :blob)
      .limit(8)

    # Track product view (for analytics)
    @product.increment!(:views_count) if @product.respond_to?(:views_count)
  end

  def search
    @products = Product.active
                      .includes(:category, images_attachments: :blob)
                      .where("name ILIKE ? OR description ILIKE ?",
                             "%#{params[:search]}%", "%#{params[:search]}%")
                      .limit(10)

    respond_to do |format|
      format.json {
        render json: {
          products: @products.map do |product|
            {
              id: product.id,
              name: product.name,
              slug: product.slug,
              price: product.price.to_f,
              category_name: product.category&.name,
              image_url: product.primary_image.present? ? url_for(product.primary_image) : nil
            }
          end
        }
      }
    end
  end

  private

  def set_product
    @product = Product.active.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
