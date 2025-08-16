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
    @shipping_methods = ShippingMethod.active
    
    # Set default shipping method if none selected
    if @checkout.shipping_method_id.blank? && @shipping_methods.any?
      @checkout.update(shipping_method_id: @shipping_methods.first.id)
    end
  end

  def update_shipping
    address_params = if params[:address].present?
      # Handle nested address params from forms
      params.require(:address).permit(
        :first_name, :last_name, :company, :address_line_1, :address_line_2,
        :city, :state_province, :postal_code, :country, :phone
      ).merge(
        shipping_method_id: params[:shipping_method_id]
      ).compact
    else
      # Handle flat params structure
      params.permit(
        :first_name, :last_name, :company, :address_line_1, :address_line_2,
        :city, :state_province, :postal_code, :country, :phone, :shipping_method_id
      )
    end

    @checkout.shipping_address_data = address_params.except(:shipping_method_id).to_h
    @checkout.shipping_method_id = address_params[:shipping_method_id] if address_params[:shipping_method_id].present?

    if @checkout.save
      @checkout.update(status: 'payment_info')
      redirect_to payment_checkout_index_path, notice: 'Shipping information saved successfully.'
    else
      @address = OpenStruct.new(address_params.except(:shipping_method_id).to_h)
      flash.now[:alert] = 'Please correct the errors below.'
      render :shipping, status: :unprocessable_entity
    end
  end

  def payment
    unless @checkout.can_proceed_to_payment?
      redirect_to shipping_checkout_index_path, alert: 'Please complete shipping information first.'
      return
    end
    
    @checkout.update(status: 'payment_info') unless @checkout.payment_info?
    
    # Create checkout service
    checkout_service = CheckoutService.new(current_cart, current_user)
    
    # Calculate totals for display
    @totals = checkout_service.calculate_totals
    
    # If we already have an order, load it
    if @checkout.order_id
      @order = Order.find(@checkout.order_id)
    end
    
    # Note: Order creation will happen in the complete action, not here
    
    # Get Stripe publishable key for frontend
    @stripe_publishable_key = Rails.application.config.stripe_publishable_key
  end

  def update_payment
    # This will be handled by Stripe on the frontend
    # We'll just update the checkout status to review
    @checkout.status = 'review'
    @checkout.billing_address_data = @checkout.shipping_address_data
    @checkout.payment_method = params[:payment_method] if params[:payment_method].present?

    if @checkout.save
      redirect_to review_checkout_index_path, notice: 'Ready for payment confirmation.'
    else
      # Set up required instance variables for rendering payment template
      checkout_service = CheckoutService.new(current_cart, current_user)
      @totals = checkout_service.calculate_totals
      
      flash.now[:alert] = 'Please correct the errors below.'
      render :payment, status: :unprocessable_entity
    end
  end

  def review
    unless @checkout.can_proceed_to_review?
      redirect_to shipping_checkout_index_path, alert: 'Please complete all previous steps.'
      return
    end
    
    @checkout.update(status: 'review') unless @checkout.review?
    
    # Load or prepare order data for display
    if @checkout.order_id
      @order = Order.find(@checkout.order_id)
    end
    
    # Calculate totals for display even if no order exists yet
    checkout_service = CheckoutService.new(current_cart, current_user)
    @totals = checkout_service.calculate_totals
  end

  def complete
    unless @checkout.review?
      redirect_to review_checkout_index_path, alert: 'Please review your order first.'
      return
    end

    # Get or create the order
    order = @checkout.order_id ? Order.find(@checkout.order_id) : nil
    
    unless order
      # Create order using the helper method
      begin
        order = create_order_from_checkout
      rescue => e
        Rails.logger.error "Order creation failed: #{e.message}"
        Rails.logger.error "Full error: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to review_checkout_index_path, alert: "There was an error completing your order: #{e.message}"
        return
      end
    end

    # Complete the order (this will set statuses and clear cart)
    complete_order(order)
    redirect_to root_path, notice: 'Order completed successfully! You will receive a confirmation email shortly.'
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

  def complete_order(order)
    ActiveRecord::Base.transaction do
      # Mark order as confirmed
      order.update!(
        status: :confirmed,
        payment_status: :paid
      )
      
      # Mark cart as converted
      if @checkout.cart.persisted?
        @checkout.cart.update!(status: 'converted')
      end
      session.delete(:cart_id) if session[:cart_id]
      
      # Mark checkout as completed
      @checkout.update!(
        status: 'completed',
        completed_at: Time.current
      )
      
      # Send confirmation email
      OrderMailer.confirmation_email(order).deliver_later if defined?(OrderMailer)
    end
  end

  def ensure_cart_not_empty
    if current_cart.cart_items.empty?
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
      country: 'US',
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
