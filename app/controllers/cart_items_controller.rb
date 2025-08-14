class CartItemsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

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
          respond_to do |format|
            format.html do
              flash[:alert] = "Only #{@product.inventory_quantity} items available in stock"
              redirect_back(fallback_location: root_path)
            end
            format.json do
              render json: {
                success: false,
                message: "Only #{@product.inventory_quantity} items available in stock"
              }, status: :unprocessable_entity
            end
          end
          return
        end

        @cart_item.update!(quantity: new_quantity)
        message = "Updated quantity in cart"
      else
        # Create new cart item
        if @product.track_inventory? && quantity > @product.inventory_quantity
          respond_to do |format|
            format.html do
              flash[:alert] = "Only #{@product.inventory_quantity} items available in stock"
              redirect_back(fallback_location: root_path)
            end
            format.json do
              render json: {
                success: false,
                message: "Only #{@product.inventory_quantity} items available in stock"
              }, status: :unprocessable_entity
            end
          end
          return
        end

        @cart_item = @cart.cart_items.create!(
          product: @product,
          quantity: quantity,
          price: @product.price,
          product_name: @product.name
        )
        message = "Added to cart"
      end

      respond_to do |format|
        format.html do
          flash[:notice] = message
          redirect_back(fallback_location: root_path)
        end
        format.json do
          render json: {
            success: true,
            message: message,
            cart_item: cart_item_json(@cart_item),
            cart_summary: cart_summary_json
          }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html do
          flash[:alert] = e.record.errors.full_messages.join(', ')
          redirect_back(fallback_location: root_path)
        end
        format.json do
          render json: {
            success: false,
            message: e.record.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /cart_items/1
  def update
    # Handle both nested cart_item[quantity] and direct quantity params
    quantity = cart_item_params&.dig(:quantity) || params[:quantity]
    quantity = quantity.to_i

    begin
      if quantity < 0
        # Reject negative quantities
        render json: {
          success: false,
          message: "Quantity cannot be negative"
        }, status: :unprocessable_entity
      elsif quantity == 0
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

  # DELETE /cart_items/clear
  def clear
    @cart.clear!

    respond_to do |format|
      format.html {
        flash[:success] = "Cart cleared successfully"
        redirect_to cart_path
      }
      format.json {
        render json: {
          success: true,
          message: "Cart cleared successfully",
          cart_summary: cart_summary_json
        }
      }
    end
  end

  private

  def set_cart
    @cart = current_cart
    Rails.logger.info "SET_CART: Current cart = #{@cart&.id}, User = #{current_user&.id}, Session = #{session.id}"
  rescue => e
    Rails.logger.error "SET_CART error: #{e.message}"
    head :internal_server_error
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "CartItem not found: ID=#{params[:id]}, Cart=#{@cart&.id}, Cart Items=#{@cart&.cart_items&.pluck(:id)}"
    head :not_found
  end

  def cart_item_json(cart_item)
    {
      id: cart_item.id,
      product_id: cart_item.product.id,
      product_name: cart_item.product_name,
      quantity: cart_item.quantity,
      unit_price: cart_item.price,
      total_price: cart_item.total_price,
      formatted_unit_price: view_context.number_to_currency(cart_item.price),
      formatted_total_price: view_context.number_to_currency(cart_item.total_price)
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
      formatted_subtotal: view_context.number_to_currency(@cart.subtotal),
      formatted_tax: view_context.number_to_currency(@cart.tax_amount),
      formatted_shipping: view_context.number_to_currency(@cart.shipping_amount),
      formatted_discount: view_context.number_to_currency(@cart.discount_amount),
      formatted_total: view_context.number_to_currency(@cart.total)
    }
  end

  def cart_item_params
    params.require(:cart_item).permit(:quantity) if params[:cart_item].present?
  end
end
