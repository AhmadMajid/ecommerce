class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :duplicate]
  before_action :set_breadcrumbs

  def index
    add_breadcrumb('Products')

    @products = Product.includes(:category, images_attachments: :blob)

    # Filtering
    @products = @products.where(category: params[:category_id]) if params[:category_id].present?
    @products = @products.where(active: params[:status] == 'active') if params[:status].present?
    @products = @products.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    # Stock filtering
    case params[:stock_status]
    when 'in_stock'
      @products = @products.in_stock
    when 'low_stock'
      @products = @products.low_stock
    when 'out_of_stock'
      @products = @products.out_of_stock
    end

    @products = @products.page(params[:page]).per(20)

    @categories = Category.active.ordered
    @total_products = Product.count
    @active_products = Product.active.count
    @low_stock_count = Product.low_stock.count
  end

  def show
    add_breadcrumb(@product.name)
    @related_products = @product.related_products
  end

  def new
    add_breadcrumb('New Product')
    @product = Product.new
    @categories = Category.active.ordered
  end

  def create
    @product = Product.new(product_params)
    
    # Handle save as draft
    if params[:save_as_draft]
      @product.active = false
      @product.published_at = nil
    end

    if @product.save
      redirect_to admin_product_path(@product), notice: 'Product was successfully created.'
    else
      @categories = Category.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    add_breadcrumb(@product.name, admin_product_path(@product))
    add_breadcrumb('Edit')
    @categories = Category.active.ordered
  end

  def update
    # Handle save as draft
    if params[:save_as_draft]
      @product.assign_attributes(product_params)
      @product.active = false
      @product.published_at = nil
    end

    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: 'Product was successfully updated.'
    else
      @categories = Category.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.can_be_deleted?
      @product.destroy
      redirect_to admin_products_path, notice: 'Product was successfully deleted.'
    else
      redirect_to admin_product_path(@product),
                  alert: 'Cannot delete product that has been ordered or is in carts.'
    end
  end

  def duplicate
    @new_product = @product.dup
    @new_product.name = "#{@product.name} (Copy)"
    @new_product.sku = nil
    @new_product.slug = nil
    @new_product.active = false

    if @new_product.save
      # Copy images
      @product.images.each do |image|
        @new_product.images.attach(image.blob)
      end

      redirect_to edit_admin_product_path(@new_product),
                  notice: 'Product duplicated successfully. Please review and update as needed.'
    else
      redirect_to admin_product_path(@product), alert: 'Failed to duplicate product.'
    end
  end

  def bulk_update
    product_ids = params[:product_ids] || []

    case params[:bulk_action]
    when 'activate'
      Product.where(id: product_ids).update_all(active: true)
      redirect_to admin_products_path, notice: 'Products activated successfully.'
    when 'deactivate'
      Product.where(id: product_ids).update_all(active: false)
      redirect_to admin_products_path, notice: 'Products deactivated successfully.'
    when 'delete'
      deletable_products = Product.where(id: product_ids).select(&:can_be_deleted?)
      deletable_products.each(&:destroy)
      redirect_to admin_products_path,
                  notice: "#{deletable_products.count} products deleted successfully."
    when 'update_category'
      if params[:new_category_id].present?
        Product.where(id: product_ids).update_all(category_id: params[:new_category_id])
        redirect_to admin_products_path, notice: 'Products category updated successfully.'
      else
        redirect_to admin_products_path, alert: 'Please select a category.'
      end
    else
      redirect_to admin_products_path, alert: 'Invalid bulk action.'
    end
  end

  def remove_image
    @product = Product.find_by!(slug: params[:product_id])
    image = @product.images.find(params[:id])
    image.purge

    redirect_to edit_admin_product_path(@product), notice: 'Image removed successfully.'
  end

  private

  def set_product
    @product = Product.find_by!(slug: params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb('Dashboard', admin_root_path)
  end

  def product_params
    params.require(:product).permit(:name, :description, :short_description, :sku, :price,
                                  :compare_at_price, :cost_price, :weight, :length, :width, :height,
                                  :inventory_quantity, :track_inventory, :allow_backorders,
                                  :low_stock_threshold, :active, :featured, :published_at,
                                  :meta_title, :meta_description, :meta_keywords, :category_id,
                                  :taxable, :requires_shipping, :tags, :sort_order, images: [])
  end
end
