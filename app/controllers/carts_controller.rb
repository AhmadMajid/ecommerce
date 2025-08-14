class CartsController < ApplicationController
  before_action :set_cart
  before_action :authenticate_user!, except: [:show, :update, :mini]

  # GET /cart
  def show
    @cart_items = @cart.cart_items.includes(:product)
    @suggested_products = Product.featured.active.limit(4) - @cart.products

    respond_to do |format|
      format.html
      format.json {
        render json: {
          item_count: @cart.item_count,
          total_price: @cart.total.to_f,
          items: @cart_items.map do |item|
            {
              id: item.id,
              product_name: item.product.name,
              quantity: item.quantity,
              unit_price: item.price.to_f,
              total_price: item.total_price.to_f
            }
          end
        }
      }
    end
  end

  # PATCH /cart
  def update
    if params[:cart_items].present?
      # Update cart item quantities
      params[:cart_items].each do |cart_item_id, item_params|
        cart_item = @cart.cart_items.find(cart_item_id)
        new_quantity = item_params[:quantity].to_i

        if new_quantity > 0
          cart_item.update!(quantity: new_quantity)
        else
          cart_item.destroy
        end
      end

      @cart.reload
      flash[:success] = "Cart updated successfully!"
    elsif params[:coupon_code].present?
      result = @cart.apply_coupon(params[:coupon_code])

      respond_to do |format|
        format.html do
          flash[result[:success] ? :success : :alert] = result[:message]
          redirect_to cart_path
        end
        format.json do
          if result[:success]
            render json: cart_summary.merge(success: true, message: result[:message])
          else
            render json: { success: false, message: result[:message] }, status: :unprocessable_entity
          end
        end
      end
      return
    elsif params[:remove_coupon]
      result = @cart.remove_coupon
      respond_to do |format|
        format.html do
          flash[:success] = result[:message]
          redirect_to cart_path
        end
        format.json do
          render json: cart_summary.merge(success: true, message: result[:message])
        end
      end
      return
    end

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.json { render json: cart_summary }
    end
  end

  # DELETE /cart
  def destroy
    @cart.clear_items
    flash[:success] = "Cart cleared successfully"

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.json { render json: { success: true, message: "Cart cleared" } }
    end
  end

  # PATCH /carts/remove_coupon
  def remove_coupon
    result = @cart.remove_coupon

    respond_to do |format|
      format.html do
        flash[:success] = result[:message]
        redirect_to cart_path
      end
      format.json do
        render json: cart_summary.merge(success: true, message: result[:message])
      end
    end
  end

  # POST /cart/merge
  def merge
    guest_session_id = params[:guest_session_id]

    if guest_session_id.present?
      guest_cart = Cart.find_by(session_id: guest_session_id, user_id: nil)
      if guest_cart && guest_cart != @cart
        @cart.merge_with!(guest_cart)
        flash[:success] = "Cart items merged successfully!"
      end
    end

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.json { render json: cart_summary }
    end
  end

  # GET /cart/mini (for AJAX requests)
  def mini
    @cart_items = @cart.cart_items.includes(:product).limit(5)
    render partial: 'shared/mini_cart', locals: { cart: @cart, cart_items: @cart_items }
  end

  private

  def set_cart
    @cart = current_cart
  end

  def cart_summary
    {
      cart: {
        id: @cart.id,
        item_count: @cart.item_count,
        unique_item_count: @cart.unique_item_count,
        subtotal: @cart.subtotal,
        tax_amount: @cart.tax_amount,
        shipping_amount: @cart.shipping_amount,
        discount_amount: @cart.discount_amount,
        total: @cart.total,
        coupon_code: @cart.coupon_code,
        formatted_subtotal: view_context.number_to_currency(@cart.subtotal),
        formatted_tax: view_context.number_to_currency(@cart.tax_amount),
        formatted_shipping: view_context.number_to_currency(@cart.shipping_amount),
        formatted_discount: view_context.number_to_currency(@cart.discount_amount),
        formatted_total: view_context.number_to_currency(@cart.total)
      }
    }
  end
end
