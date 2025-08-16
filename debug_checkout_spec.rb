require 'rails_helper'

RSpec.describe 'Debug Checkout Payment', type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:cart) { create(:cart, user: user) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }
  let(:checkout) { create(:checkout, :with_shipping_info, user: user, cart: cart) }

  before do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }

    cart_item # ensure cart has items

    allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(cart)
    allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)
  end

  it 'debugs the payment step' do
    puts "Checkout shipping_address: #{checkout.shipping_address}"
    puts "Checkout shipping_method_id: #{checkout.shipping_method_id}"
    puts "Checkout can_proceed_to_payment?: #{checkout.can_proceed_to_payment?}"
    
    get payment_checkout_index_path
    puts "Response status: #{response.status}"
    puts "Response location: #{response.location}"
    
    if response.status == 302
      puts "Redirected to: #{response.location}"
    end
  end
end
