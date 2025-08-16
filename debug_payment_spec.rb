require 'rails_helper'

RSpec.describe 'Debug Checkout Payment', type: :request do
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

    # Mock the current cart
    allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(cart)
    
    # Mock cart.items to return the association, not just an array
    allow(cart).to receive(:items).and_return(cart.cart_items)
    allow(cart).to receive_message_chain(:items, :empty?).and_return(false)

    # Mock the checkout finding
    allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)
    allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
      controller.instance_variable_set(:@checkout, checkout)
    end
  end

  it 'debugs the payment step' do
    puts "Before request:"
    puts "- Checkout can proceed: #{checkout.can_proceed_to_payment?}"
    puts "- Cart items: #{cart.cart_items.count}"
    puts "- Cart items loaded: #{cart.cart_items.loaded?}"
    
    get payment_checkout_index_path
    
    puts "After request:"
    puts "- Response status: #{response.status}"
    puts "- Response location: #{response.location}" if response.status == 302
    puts "- Response body (first 200 chars): #{response.body[0, 200]}"
    
    # Just check what happens
    if response.status == 200
      expect(response).to have_http_status(:success)
      puts "✅ Payment page rendered successfully"
    else
      puts "❌ Redirected to: #{response.location}"
    end
  end
end
