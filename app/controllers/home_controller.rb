class HomeController < ApplicationController
  def index
    @hero_products = Product.active.featured.includes(:category, images_attachments: :blob).limit(3)
    @featured_products = Product.active.featured.includes(:category, images_attachments: :blob).limit(8)
    @popular_categories = Category.active.featured.includes(:parent, image_attachment: :blob).limit(6)
    @latest_products = Product.active.includes(:category, images_attachments: :blob).recent.limit(8)
  end
end
