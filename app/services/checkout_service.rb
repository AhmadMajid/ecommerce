class CheckoutService
  attr_reader :cart, :user, :errors

  def initialize(cart, user = nil)
    @cart = cart
    @user = user
    @errors = []
  end

  def create_order_from_cart(checkout_params = {})
    return false unless valid_cart?

    ActiveRecord::Base.transaction do
      order = build_order(checkout_params)
      
      if order.save
        create_order_items(order)
        create_payment_intent(order)
        clear_cart
        order
      else
        @errors.concat(order.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end
  rescue => e
    Rails.logger.error "Checkout error: #{e.message}"
    @errors << "Unable to process order: #{e.message}"
    false
  end

  def calculate_totals
    return { subtotal: 0, tax: 0, shipping: 0, total: 0 } if cart.blank? || cart.cart_items.empty?

    subtotal = cart.cart_items.sum { |item| item.quantity * item.product.price }
    tax = calculate_tax(subtotal)
    shipping = calculate_shipping(subtotal)
    total = subtotal + tax + shipping

    {
      subtotal: subtotal,
      tax: tax,
      shipping: shipping,
      total: total
    }
  end

  private

  def valid_cart?
    if cart.blank? || cart.cart_items.empty?
      @errors << "Cart is empty"
      return false
    end

    # Check inventory
    cart.cart_items.each do |item|
      if item.product.track_inventory && item.product.inventory_quantity < item.quantity
        @errors << "#{item.product.name} is out of stock"
        return false
      end
    end

    true
  end

  def build_order(checkout_params)
    totals = calculate_totals

    order_params = {
      user: user,
      email: user&.email || checkout_params[:email],
      status: :pending,
      payment_status: :payment_pending,
      fulfillment_status: :unfulfilled,
      currency: 'USD',
      subtotal: totals[:subtotal],
      tax_amount: totals[:tax],
      shipping_amount: totals[:shipping],
      total: totals[:total]
    }

    # Add address information if provided
    if checkout_params[:shipping_address].present?
      order_params.merge!(extract_shipping_address(checkout_params[:shipping_address]))
    end

    if checkout_params[:billing_address].present?
      order_params.merge!(extract_billing_address(checkout_params[:billing_address]))
    end

    Order.new(order_params)
  end

  def create_order_items(order)
    cart.cart_items.each do |cart_item|
      product = cart_item.product
      
      order.order_items.create!(
        product: product,
        product_variant: cart_item.respond_to?(:product_variant) ? cart_item.product_variant : nil,
        product_name: product.name,
        product_sku: product.sku,
        variant_title: cart_item.respond_to?(:product_variant) ? cart_item.product_variant&.title : nil,
        variant_sku: cart_item.respond_to?(:product_variant) ? cart_item.product_variant&.sku : nil,
        quantity: cart_item.quantity,
        unit_price: product.price,
        total_price: cart_item.quantity * product.price,
        taxable: product.taxable?
      )

      # Reduce inventory if tracked
      if product.track_inventory?
        product.decrement!(:inventory_quantity, cart_item.quantity)
      end
    end
  end

  def create_payment_intent(order)
    PaymentService.create_payment_intent(order)
  end

  def clear_cart
    cart.cart_items.destroy_all
  end

  def calculate_tax(subtotal)
    # Simple 8.5% tax calculation - you might want to use a tax service
    (subtotal * 0.085).round(2)
  end

  def calculate_shipping(subtotal = nil)
    # Flat rate shipping for now - you might want to integrate with shipping APIs
    subtotal ||= cart.cart_items.sum { |item| item.quantity * item.product.price }
    return 0 if subtotal >= 75 # Free shipping over $75
    9.99
  end

  def extract_shipping_address(address_params)
    {
      shipping_first_name: address_params[:first_name],
      shipping_last_name: address_params[:last_name],
      shipping_company: address_params[:company],
      shipping_address_line_1: address_params[:address_line_1],
      shipping_address_line_2: address_params[:address_line_2],
      shipping_city: address_params[:city],
      shipping_state_province: address_params[:state_province],
      shipping_postal_code: address_params[:postal_code],
      shipping_country: address_params[:country],
      shipping_phone: address_params[:phone]
    }
  end

  def extract_billing_address(address_params)
    {
      billing_first_name: address_params[:first_name],
      billing_last_name: address_params[:last_name],
      billing_company: address_params[:company],
      billing_address_line_1: address_params[:address_line_1],
      billing_address_line_2: address_params[:address_line_2],
      billing_city: address_params[:city],
      billing_state_province: address_params[:state_province],
      billing_postal_code: address_params[:postal_code],
      billing_country: address_params[:country],
      billing_phone: address_params[:phone]
    }
  end
end
