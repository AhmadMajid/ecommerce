require 'rails_helper'
require 'cgi'

RSpec.describe 'Full Application Integration', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }
  let(:category) { create(:category, name: 'Test Category') }
  let(:product) { create(:product, category: category) }

  describe 'Basic Application Health' do
    it 'loads the home page' do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it 'has working authentication routes' do
      get new_user_registration_path
      expect(response).to have_http_status(:success)

      get new_user_session_path
      expect(response).to have_http_status(:success)
    end

    it 'can create and authenticate users' do
      expect { create(:user) }.to change { User.count }.by(1)

      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'Product Management' do
    it 'displays products' do
      product
      get products_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'shows product details' do
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'displays categories' do
      category
      get categories_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Test Category')
    end
  end

  describe 'Shopping Cart Workflow' do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
    end

    it 'can add items to cart' do
      expect {
        post cart_items_path, params: { product_id: product.id, quantity: 2 }
      }.to change {
        Cart.joins(:cart_items).where(user: user).first&.cart_items&.count || 0
      }.by(1)
    end

    it 'displays cart contents' do
      cart = create(:cart, user: user)
      create(:cart_item, cart: cart, product: product)

      get cart_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'can update cart quantities' do
      cart = create(:cart, user: user)
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 1)

      patch cart_path, params: {
        cart_items: { cart_item.id.to_s => { quantity: 3 } }
      }

      expect(cart_item.reload.quantity).to eq(3)
    end
  end

  describe 'Checkout Process' do
    let(:cart) { create(:cart, user: user) }
    let(:cart_item) { create(:cart_item, cart: cart, product: product) }
    let(:shipping_method) { create(:shipping_method) }

    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
      cart_item # ensure cart has items
    end

    it 'can start checkout process' do
      get new_checkout_path
      expect(response).to redirect_to(shipping_checkout_index_path)
    end

    it 'displays shipping step' do
      checkout = create(:checkout, user: user, cart: cart)
      allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)

      get shipping_checkout_index_path
      expect(response).to have_http_status(:success)
    end

    xit 'can complete checkout with valid data' do
      sign_in user

      # Clean up any existing checkouts for this user
      Checkout.where(user: user).destroy_all

      # Ensure we have an active cart for the user
      cart.update!(user: user, status: 'active')

      # Create a checkout that is properly ready for completion
      checkout = create(:checkout, :ready_for_review, user: user, cart: cart)

      post complete_checkout_index_path

      puts "Response status: #{response.status}"
      puts "Response location: #{response.location}" if response.redirect?

      expect(checkout.reload.status).to eq('completed')
    end
  end

  describe 'Error Handling' do
    it 'handles 404 errors gracefully' do
      get '/nonexistent-page'
      expect(response).to have_http_status(:not_found)
    end

    it 'requires authentication for protected routes' do
      get new_checkout_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
