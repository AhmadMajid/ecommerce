module ApplicationHelper
  def current_user_review_for(product)
    return nil unless user_signed_in?
    @current_user_reviews ||= {}
    @current_user_reviews[product.id] ||= current_user.reviews.find_by(product: product)
  end
end
