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

  # PATCH/PUT /cart_items/1
  def update
    quantity = params[:quantity].to_i

    begin
      if quantity <= 0
        @cart_item.destroy
        message = "Item removed from cart"
        render json: {
          success: true,
          message: message,
          cart_summary: cart_summary_json
        }
      else
        # Check stock availability
        if @cart_item.product.track_inventory? && quantity > @cart_item.product.inventory_quantity
          render json: {
            success: false,
            message: "Only #{@cart_item.product.inventory_quantity} items available in stock"
          }, status: :unprocessable_entity
          return
        end

        @cart_item.update!(quantity: quantity)
        message = "Cart updated"

        render json: {
          success: true,
          message: message,
          cart_item: cart_item_json(@cart_item),
          cart_summary: cart_summary_json
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        success: false,
        message: e.record.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # DELETE /cart_items/1
  def destroy
    @cart_item.destroy

    respond_to do |format|
      format.html {
        flash[:success] = "Item removed from cart"
        redirect_to cart_path
      }
      format.json {
        render json: {
          success: true,
          message: "Item removed from cart",
          cart_summary: cart_summary_json
        }
      }
    end
  end

  private

  def set_cart
    @cart = current_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end

  def cart_item_json(cart_item)
    {
      id: cart_item.id,
      product_id: cart_item.product.id,
      product_name: cart_item.product_name,
      quantity: cart_item.quantity,
      unit_price: cart_item.unit_price,
      total_price: cart_item.total_price,
      formatted_unit_price: number_to_currency(cart_item.unit_price),
      formatted_total_price: number_to_currency(cart_item.total_price)
    }
  end

  def cart_summary_json
    {
      item_count: @cart.item_count,
      unique_item_count: @cart.unique_item_count,
      subtotal: @cart.subtotal,
      tax_amount: @cart.tax_amount,
      shipping_amount: @cart.shipping_amount,
      discount_amount: @cart.discount_amount,
      total: @cart.total,
      formatted_subtotal: number_to_currency(@cart.subtotal),
      formatted_tax: number_to_currency(@cart.tax_amount),
      formatted_shipping: number_to_currency(@cart.shipping_amount),
      formatted_discount: number_to_currency(@cart.discount_amount),
      formatted_total: number_to_currency(@cart.total)
    }
  end
end
