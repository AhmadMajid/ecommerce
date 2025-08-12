class Admin::DashboardController < Admin::BaseController
  def index
    add_breadcrumb('Dashboard')

    @stats = {
      products_count: Product.count,
      active_products_count: Product.active.count,
      categories_count: Category.count,
      low_stock_products: Product.low_stock.count,
      out_of_stock_products: Product.out_of_stock.count
    }

    @recent_products = Product.recent.limit(5)
    @low_stock_products = Product.low_stock.includes(:category).limit(10)
  end
end
