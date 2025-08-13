class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_review, only: [:edit, :update, :destroy]
  before_action :check_existing_review, only: [:create]
  before_action :check_review_owner, only: [:edit, :update, :destroy]

  def new
    @review = @product.reviews.build
  end

  def create
    @review = @product.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      redirect_to @product, notice: 'Thank you for your review!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @review is set by before_action
  end

  def update
    if @review.update(review_params)
      redirect_to @product, notice: 'Your review has been updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to @product, notice: 'Your review has been deleted.'
  end

  private

  def set_product
    @product = Product.find_by!(slug: params[:product_slug])
  end

  def set_review
    @review = @product.reviews.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :title, :content)
  end

  def check_existing_review
    if current_user.reviews.exists?(product: @product)
      redirect_to @product, alert: 'You have already reviewed this product.'
    end
  end

  def check_review_owner
    unless @review.user == current_user
      redirect_to @product, alert: 'You can only edit your own reviews.'
    end
  end
end
