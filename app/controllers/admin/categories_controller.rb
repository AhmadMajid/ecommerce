class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  def index
    add_breadcrumb('Categories')

    @categories = Category.includes(:parent, :products)

    # Apply search filter
    if params[:search].present?
      @categories = @categories.where("name ILIKE ? OR description ILIKE ?", 
                                     "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Apply parent category filter
    if params[:parent_id].present?
      if params[:parent_id] == 'root'
        @categories = @categories.where(parent_id: nil)
      else
        @categories = @categories.where(parent_id: params[:parent_id])
      end
    end

    # Apply status filter
    if params[:status].present?
      case params[:status]
      when 'active'
        @categories = @categories.where(active: true)
      when 'inactive'
        @categories = @categories.where(active: false)
      when 'featured'
        @categories = @categories.where(featured: true)
      end
    end

    @categories = @categories.ordered
                             .page(params[:page])
                             .per(20)

    @root_categories = Category.root_categories.ordered
    @parent_categories = Category.root_categories.active.ordered
  end

  def show
    add_breadcrumb(@category.name)
    @products = @category.products.includes(:category).page(params[:page]).per(10)
  end

  def new
    add_breadcrumb('New Category')
    @category = Category.new
    @parent_categories = Category.root_categories.active.ordered
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_category_path(@category), notice: 'Category was successfully created.'
    else
      @parent_categories = Category.root_categories.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    add_breadcrumb(@category.name, admin_category_path(@category))
    add_breadcrumb('Edit')
    @parent_categories = Category.where.not(id: [@category.id] + @category.descendants.pluck(:id))
                                .root_categories.active.ordered
  end

  def update
    if @category.update(category_params)
      redirect_to admin_category_path(@category), notice: 'Category was successfully updated.'
    else
      @parent_categories = Category.where.not(id: [@category.id] + @category.descendants.pluck(:id))
                                  .root_categories.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.can_be_deleted?
      @category.destroy
      redirect_to admin_categories_path, notice: 'Category was successfully deleted.'
    else
      redirect_to admin_category_path(@category),
                  alert: 'Cannot delete category with products or subcategories.'
    end
  end

  def bulk_update
    case params[:bulk_action]
    when 'activate'
      Category.where(id: params[:category_ids]).update_all(active: true)
      redirect_to admin_categories_path, notice: 'Categories activated successfully.'
    when 'deactivate'
      Category.where(id: params[:category_ids]).update_all(active: false)
      redirect_to admin_categories_path, notice: 'Categories deactivated successfully.'
    when 'delete'
      deletable_categories = Category.where(id: params[:category_ids]).select(&:can_be_deleted?)
      deletable_categories.each(&:destroy)
      redirect_to admin_categories_path,
                  notice: "#{deletable_categories.count} categories deleted successfully."
    else
      redirect_to admin_categories_path, alert: 'Invalid bulk action.'
    end
  end

  private

  def set_category
    @category = Category.find_by!(slug: params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb('Dashboard', admin_root_path)
  end

  def category_params
    params.require(:category).permit(:name, :description, :parent_id, :active, :featured,
                                   :sort_order, :meta_title, :meta_description, :image, :banner_image)
  end
end
