class CartItemsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:show, :update, :destroy]

  # POST /cart_items
  def create
    @product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i.clamp(1, 999)

    # Check if item already exists in cart
    @cart_item = @cart.cart_items.find_by(product: @product)

    begin
      if @cart_item
        # Update quantity if item already in cart
        new_quantity = @cart_item.quantity + quantity

        # Check stock availability
        if @product.track_inventory? && new_quantity > @product.inventory_quantity
          render json: {
            success: false,
            message: "Only #{@product.inventory_quantity} items available in stock"
          }, status: :unprocessable_entity
          return
        end

        @cart_item.update!(quantity: new_quantity)
        message = "Updated quantity in cart"
      else
        # Create new cart item
        if @product.track_inventory? && quantity > @product.inventory_quantity
          render json: {
            success: false,
            message: "Only #{@product.inventory_quantity} items available in stock"
          }, status: :unprocessable_entity
          return
        end

        @cart_item = @cart.cart_items.create!(
          product: @product,
          quantity: quantity,
          unit_price: @product.price,
          total_price: @product.price * quantity,
          product_name: @product.name
        )
        message = "Added to cart"
      end

      render json: {
        success: true,
        message: message,
        cart_item: cart_item_json(@cart_item),
        cart_summary: cart_summary_json
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        message: e.record.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end
    end

    # Update cart totals
    @cart.update_totals!

    # Return success response
    render json: {
      success: true,
      message: "Product added to cart successfully!",
      cart_count: @cart.cart_items.sum(:quantity),
      cart_total: @cart.total_amount,
      item: {
        id: @cart_item.id,
        product_name: @product.name,
        quantity: @cart_item.quantity,
        price: @cart_item.price,
        total: @cart_item.total_price
      }
    }
  end

  # GET /cart_items
  def index
    @cart_items = @cart.cart_items.includes(:product)
    @total = @cart.total_amount
  end

  # PATCH/PUT /cart_items/1
  def update
    quantity = params[:quantity].to_i

    if quantity <= 0
      @cart_item.destroy
      message = "Item removed from cart"
    else
      # Check stock availability
      if @cart_item.product.track_inventory? && quantity > @cart_item.product.inventory_quantity
        render json: {
          success: false,
          message: "Only #{@cart_item.product.inventory_quantity} items available in stock"
        }, status: :unprocessable_entity
        return
      end

      @cart_item.update(quantity: quantity)
      message = "Cart updated successfully"
    end

    @cart.update_totals!

    render json: {
      success: true,
      message: message,
      cart_count: @cart.cart_items.sum(:quantity),
      cart_total: @cart.total_amount
    }
  end

  # DELETE /cart_items/1
  def destroy
    @cart_item.destroy
    @cart.update_totals!

    respond_to do |format|
      format.html { redirect_to cart_items_path, notice: 'Item removed from cart.' }
      format.json {
        render json: {
          success: true,
          message: "Item removed from cart",
          cart_count: @cart.cart_items.sum(:quantity),
          cart_total: @cart.total_amount
        }
      }
    end
  end

  # DELETE /cart_items/clear
  def clear
    @cart.cart_items.destroy_all
    @cart.update_totals!

    redirect_to cart_items_path, notice: 'Cart cleared successfully.'
  end

  private

  def ensure_cart
    @cart = current_user.cart || current_user.create_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end

  def cart_item_params
    params.require(:cart_item).permit(:product_id, :quantity)
  end
end
