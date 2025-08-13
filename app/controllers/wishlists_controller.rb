class WishlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:create, :destroy]

  def index
    @wishlists = current_user.wishlists.includes(:product)
  end

  def create
    @wishlist = current_user.wishlists.find_or_initialize_by(product: @product)

    if @wishlist.persisted?
      render json: { status: 'already_exists', message: 'Product already in wishlist' }
    elsif @wishlist.save
      render json: {
        status: 'success',
        message: 'Product added to wishlist',
        wishlist_count: current_user.wishlists.count
      }
    else
      render json: { status: 'error', message: 'Could not add to wishlist' }
    end
  end

  def destroy
    @wishlist = current_user.wishlists.find_by(product: @product)

    if @wishlist&.destroy
      render json: {
        status: 'success',
        message: 'Product removed from wishlist',
        wishlist_count: current_user.wishlists.count
      }
    else
      render json: { status: 'error', message: 'Could not remove from wishlist' }
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
