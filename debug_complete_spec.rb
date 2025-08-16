require 'rails_helper'

RSpec.describe 'Debug Complete Checkout', type: :request do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:product) { create(:product) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product) }

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
  end

  it 'debugs complete checkout flow' do
    # Create a checkout ready for review
    checkout = create(:checkout, :ready_for_review, user: user, cart: cart)
    
    puts "Before completion:"
    puts "- Checkout status: #{checkout.status}"
    puts "- Checkout can proceed to review: #{checkout.can_proceed_to_review?}"
    puts "- Cart status: #{cart.status}"
    puts "- Cart items count: #{cart.cart_items.count}"
    
    # Mock the checkout finding
    allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)
    allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
      controller.instance_variable_set(:@checkout, checkout)
    end

    post complete_checkout_index_path
    
    puts "\nAfter completion:"
    puts "- Response status: #{response.status}"
    puts "- Response location: #{response.location}"
    puts "- Flash notices: #{flash[:notice]}"
    puts "- Flash alerts: #{flash[:alert]}"
    
    # Check the final state
    checkout.reload
    cart.reload
    puts "\nFinal state:"
    puts "- Checkout status: #{checkout.status}"
    puts "- Cart status: #{cart.status}"
  end
end
