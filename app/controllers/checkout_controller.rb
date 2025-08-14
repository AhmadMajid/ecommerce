require 'ostruct'

class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_cart_not_empty
  before_action :set_checkout_session, except: [:new]
  before_action :set_shipping_methods, only: [:shipping, :update_shipping]

  def new
    # Start a new checkout session
    @checkout = find_or_create_checkout_session
    redirect_to shipping_checkout_index_path
  end

  def shipping
    @checkout.update(status: 'shipping_info') unless @checkout.shipping_info?
    @address = build_shipping_address
  end

  def update_shipping
    address_params = params.require(:address).permit(
      :first_name, :last_name, :company, :address_line_1, :address_line_2,
      :city, :state_province, :postal_code, :country, :phone
    )

    @checkout.shipping_address_data = address_params.to_h
    @checkout.shipping_method_id = params[:shipping_method_id] if params[:shipping_method_id].present?

    if @checkout.save
      @checkout.update(status: 'payment_info')
      redirect_to payment_checkout_index_path, notice: 'Shipping information saved successfully.'
    else
      @address = OpenStruct.new(address_params.to_h)
      flash.now[:alert] = 'Please correct the errors below.'
      render :shipping, status: :unprocessable_entity
    end
  end

  def payment
    redirect_to shipping_checkout_index_path, alert: 'Please complete shipping information first.' unless @checkout.can_proceed_to_payment?
    @checkout.update(status: 'payment_info') unless @checkout.payment_info?
  end

  def update_payment
    # For now, we'll just mark payment as completed
    # In a real application, you'd integrate with a payment processor here
    @checkout.payment_method = params[:payment_method] || 'credit_card'
    @checkout.status = 'review'

    # Set billing address (for now, same as shipping)
    @checkout.billing_address_data = @checkout.shipping_address_data

    if @checkout.save
      redirect_to review_checkout_index_path, notice: 'Payment information saved successfully.'
    else
      flash.now[:alert] = 'Please correct the errors below.'
      render :payment, status: :unprocessable_entity
    end
  end

  def review
    redirect_to shipping_checkout_index_path, alert: 'Please complete all previous steps.' unless @checkout.can_proceed_to_review?
    @checkout.update(status: 'review') unless @checkout.review?
  end

  def complete
    Rails.logger.debug "Complete action called, @checkout: #{@checkout.inspect}"
    Rails.logger.debug "Checkout status: #{@checkout.status.inspect}, review?: #{@checkout.review?}" if @checkout

    unless @checkout.review?
      redirect_to review_checkout_index_path, alert: 'Please review your order first.'
      return
    end

    begin
      ActiveRecord::Base.transaction do
        # Create the order from the checkout
        Rails.logger.debug "About to create order from checkout"
        # Re-enable order creation now that tables exist
        order = create_order_from_checkout
        Rails.logger.debug "Order created successfully: #{order.id}"

        # Mark the cart as converted instead of deleting it
        Rails.logger.debug "About to mark cart as converted: #{@checkout.cart.inspect}"
        if @checkout.cart.persisted?
          @checkout.cart.update!(status: 'converted')
          Rails.logger.debug "Cart status updated to: #{@checkout.cart.reload.status}"
        end
        session.delete(:cart_id) if session[:cart_id]

        # Mark checkout as completed
        Rails.logger.debug "Updating checkout status to completed"
        Rails.logger.debug "Checkout before update: #{@checkout.inspect}"
        @checkout.update!(
          status: 'completed',
          completed_at: Time.current
        )
        Rails.logger.debug "Checkout status updated: #{@checkout.reload.status}"
      end

      Rails.logger.debug "Redirecting to root with success message"
      redirect_to root_path, notice: 'Order completed successfully! This was a demo checkout - no real payment was processed.'
    rescue => e
      Rails.logger.error "Checkout completion failed: #{e.message}"
      Rails.logger.error e.backtrace.join("
")
      redirect_to review_checkout_index_path, alert: 'There was an error completing your order. Please try again.'
    end
  end

  def apply_coupon
    coupon_code = params[:coupon_code]&.strip&.upcase

    if coupon_code.blank?
      redirect_back(fallback_location: shipping_checkout_index_path, alert: 'Please enter a coupon code.')
      return
    end

    result = current_cart.apply_coupon(coupon_code)

    if result[:success]
      # Update checkout totals to reflect the coupon
      @checkout.calculate_totals
      @checkout.save!
      redirect_back(fallback_location: shipping_checkout_index_path, notice: result[:message])
    else
      redirect_back(fallback_location: shipping_checkout_index_path, alert: result[:message])
    end
  end

  def remove_coupon
    result = current_cart.remove_coupon

    # Update checkout totals
    @checkout.calculate_totals
    @checkout.save!

    redirect_back(fallback_location: shipping_checkout_index_path, notice: result[:message])
  end

  def destroy
    @checkout&.destroy
    redirect_to cart_path, notice: 'Checkout cancelled.'
  end

  private

  def ensure_cart_not_empty
    if current_cart.items.empty?
      redirect_to cart_path, alert: 'Your cart is empty. Please add items before checkout.'
    end
  end

  def set_checkout_session
    @checkout = find_checkout_session
    unless @checkout
      redirect_to new_checkout_path, alert: 'Please start a new checkout session.'
    end
  end

  def set_shipping_methods
    @shipping_methods = ShippingMethod.active.by_sort_order
  end

  def find_or_create_checkout_session
    # Try to find existing active checkout
    checkout = find_checkout_session

    # Create new checkout if none exists or if existing one is expired/completed
    if checkout.nil? || checkout.expired? || checkout.completed?
      checkout = create_new_checkout_session
    end

    checkout
  end

  def find_checkout_session
    if current_user
      Checkout.where(user: current_user)
              .where(status: ['started', 'shipping_info', 'payment_info', 'review'])
              .where('expires_at > ?', Time.current)
              .first
    else
      Checkout.where(session_id: session.id.to_s)
              .where(status: ['started', 'shipping_info', 'payment_info', 'review'])
              .where('expires_at > ?', Time.current)
              .first
    end
  end

  def create_new_checkout_session
    checkout_params = {
      cart: current_cart,
      status: 'started',
      expires_at: 2.hours.from_now
    }

    if current_user
      checkout_params[:user] = current_user
      checkout_params[:session_id] = session.id.to_s
    else
      checkout_params[:session_id] = session.id.to_s
    end

    Checkout.create!(checkout_params)
  end

  def build_shipping_address
    # Try to use existing shipping address from checkout
    if @checkout.shipping_address_data.present?
      return OpenStruct.new(@checkout.shipping_address_data)
    end

    # Try to use user's default shipping address
    if current_user&.addresses&.shipping&.default&.first
      address = current_user.addresses.shipping.default.first
      return OpenStruct.new(
        first_name: address.first_name,
        last_name: address.last_name,
        company: address.company,
        address_line_1: address.address_line_1,
        address_line_2: address.address_line_2,
        city: address.city,
        state_province: address.state_province,
        postal_code: address.postal_code,
        country: address.country,
        phone: address.phone
      )
    end

    # Default empty address
    OpenStruct.new(
      first_name: current_user&.first_name,
      last_name: current_user&.last_name,
      company: '',
      address_line_1: '',
      address_line_2: '',
      city: '',
      state_province: '',
      postal_code: '',
      country: 'United States',
      phone: ''
    )
  end

  def create_order_from_checkout
    Rails.logger.debug "Creating order from checkout..."
    Rails.logger.debug "Current user: #{current_user.inspect}"
    Rails.logger.debug "Checkout cart: #{@checkout.cart.inspect}"
    Rails.logger.debug "Cart total_price: #{@checkout.cart.total_price}"
    Rails.logger.debug "Cart items: #{@checkout.cart.cart_items.inspect}"
    Rails.logger.debug "Checkout: #{@checkout.inspect}"

    # Ensure cart has items and recalculate totals
    if @checkout.cart.cart_items.empty?
      raise "Cannot create order from empty cart"
    end

    @checkout.cart.recalculate_totals!

    # Create an actual order record from the checkout
    order_total = @checkout.cart.total_price > 0 ? @checkout.cart.total_price : @checkout.cart.subtotal

    order_attrs = {
      user: current_user,
      order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
      email: current_user&.email || params[:guest_email] || 'test@example.com',
      total: order_total,
      status: 'pending'
    }

    Rails.logger.debug "About to create order with attributes: #{order_attrs.inspect}"

    begin
      order = Order.create!(order_attrs)
      Rails.logger.debug "Order created: #{order.inspect}"
    rescue => e
      Rails.logger.error "Order creation failed: #{e.class}: #{e.message}"
      raise e
    end

    # Create order items from cart items
    @checkout.cart.cart_items.each do |cart_item|
      Rails.logger.debug "Creating order item from cart item: #{cart_item.inspect}"
      order_item_attrs = {
        product: cart_item.product,
        product_name: cart_item.product_name,
        product_sku: cart_item.product.sku,
        quantity: cart_item.quantity,
        unit_price: cart_item.price,
        total_price: cart_item.total_price
      }
      Rails.logger.debug "Order item attributes: #{order_item_attrs.inspect}"

      order.order_items.create!(order_item_attrs)
    end

    Rails.logger.debug "All order items created"
    order
  rescue => e
    Rails.logger.error "Error in create_order_from_checkout: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
