require 'rails_helper'

RSpec.describe 'Debug Payment GET', type: :request do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:product) { create(:product) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product) }
  let(:checkout) { create(:checkout, :with_shipping_info, user: user, cart: cart) }

  before do
    # Ensure cart item is created first
    cart_item
    
    # Sign in the user
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }

    # Mock the current cart and cart items
    allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(cart)
    allow(cart).to receive(:items).and_return(cart.cart_items)
    allow(cart).to receive_message_chain(:items, :empty?).and_return(false)

    # Mock the checkout finding
    allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)
  end

  it 'debugs GET /checkout/payment redirect issue' do
    puts "Before payment request:"
    puts "- Checkout status: #{checkout.status}"
    puts "- Checkout can_proceed_to_payment?: #{checkout.can_proceed_to_payment?}"
    puts "- Shipping method ID: #{checkout.shipping_method_id}"
    puts "- Shipping address present: #{checkout.shipping_address.present?}"
    
    get payment_checkout_index_path
    
    puts "\nAfter payment request:"
    puts "- Response status: #{response.status}"
    puts "- Redirect location: #{response.location}" if response.status == 302
    puts "- Flash alerts: #{flash[:alert]}"
    puts "- Flash notices: #{flash[:notice]}"
    
    # Check what the checkout state is after the request
    fresh_checkout = Checkout.find(checkout.id)
    puts "\nFresh checkout state:"
    puts "- Status: #{fresh_checkout.status}"
    puts "- Can proceed to payment: #{fresh_checkout.can_proceed_to_payment?}"
  end
end
