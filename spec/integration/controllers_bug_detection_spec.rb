require 'rails_helper'

RSpec.describe 'Controllers Bug Detection', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }
  let(:category) { create(:category) }
  let(:product) { create(:product, category: category) }

  describe 'HomeController' do
    it 'renders index without errors' do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'ProductsController' do
    it 'handles index page' do
      product
      get products_path
      expect(response).to have_http_status(:success)
    end

    it 'handles show with valid slug' do
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
    end

    it 'handles invalid slug' do
      get product_path('invalid-slug')
      expect(response).to have_http_status(:not_found)
    end

    it 'filters by category' do
      get products_path, params: { category_id: category.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'CategoriesController' do
    it 'displays categories index' do
      category
      get categories_path
      expect(response).to have_http_status(:success)
    end

    it 'shows category details' do
      get category_path(category.slug)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'CartsController' do
    context 'when not authenticated' do
      it 'shows guest cart' do
        get cart_path
        expect(response).to have_http_status(:success)
      end

      it 'can add items to guest cart' do
        # Use the helper to create guest cart with proper mocking
        guest_cart = authenticate_guest_with_cart

        post cart_items_path, params: { product_id: product.id, quantity: 1 }

        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated' do
      let(:cart) { create(:cart, user: user, status: 'active') }

      before do
        # Mock the set_cart method to use our test cart
        allow_any_instance_of(CartsController).to receive(:set_cart) do |controller|
          controller.instance_variable_set(:@cart, cart)
        end
      end

      it 'shows user cart' do
        get cart_path
        expect(response).to have_http_status(:success)
      end

      it 'can add items to user cart' do
        post cart_items_path, params: { product_id: product.id, quantity: 1 }
        expect(response).to have_http_status(:success)
      end

      it 'can update cart items' do
        cart_item = create(:cart_item, cart: cart, product: product, quantity: 1)

        patch cart_path, params: {
          cart_items: { cart_item.id.to_s => { quantity: 3 } }
        }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(cart_item.reload.quantity).to eq(3)
      end
    end
  end

  describe 'CartItemsController' do
    context 'when authenticated user' do
      let(:user) { create(:user) }
      let!(:cart) { create(:cart, user: user, status: 'active') }
      let!(:cart_item) { create(:cart_item, cart: cart, product: product) }

      before do
        # Ensure no other active carts exist for this user
        user.carts.where.not(id: cart.id).update_all(status: 'inactive')

        # Skip authentication by stubbing the before_action method
        allow_any_instance_of(CartItemsController).to receive(:set_cart) do |controller|
          controller.instance_variable_set(:@cart, cart)
        end

        allow_any_instance_of(CartItemsController).to receive(:set_cart_item) do |controller|
          controller.instance_variable_set(:@cart_item, cart_item)
        end
      end

      it 'can update item quantity' do
        patch cart_item_path(cart_item), params: {
          cart_item: { quantity: 5 }
        }

        expect(response).to have_http_status(:success)
        expect(cart_item.reload.quantity).to eq(5)
      end

      it 'can remove item from cart' do
        expect {
          delete cart_item_path(cart_item)
        }.to change { cart.cart_items.count }.by(-1)
      end

      it 'handles invalid quantity updates' do
        patch cart_item_path(cart_item), params: {
          cart_item: { quantity: -1 }
        }

        # Should either reject the update or handle gracefully
        expect(cart_item.reload.quantity).not_to eq(-1)
      end
    end

    context 'when guest user' do
      let!(:guest_cart) { authenticate_guest_with_cart }
      let!(:cart_item) { create(:cart_item, cart: guest_cart, product: product) }

      it 'can update guest cart item quantity' do
        patch cart_item_path(cart_item), params: {
          cart_item: { quantity: 3 }
        }


        expect(response).to have_http_status(:success)
        expect(cart_item.reload.quantity).to eq(3)
      end
    end
  end

  describe 'CheckoutController' do
    let(:cart) { create(:cart, user: user, status: 'active') }
    let(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }
    let(:shipping_method) { create(:shipping_method) }

    before do
      # Sign in the user using a request
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }

      cart_item # ensure cart has items

      # Create a checkout session with minimal requirements
      @checkout = create(:checkout, user: user, cart: cart, status: 'started')

      # Mock the controller methods
      allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(cart)
      allow_any_instance_of(CheckoutController).to receive(:ensure_cart_not_empty).and_return(true)
      allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
        controller.instance_variable_set(:@checkout, @checkout)
      end
    end

    it 'redirects to shipping when starting checkout' do
      get new_checkout_path
      expect(response).to redirect_to(shipping_checkout_index_path)
    end

    it 'shows shipping step' do
      get shipping_checkout_index_path
      expect(response).to have_http_status(:success)
    end

    it 'processes shipping information' do
      patch update_shipping_checkout_index_path, params: {
        address: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        },
        shipping_method_id: shipping_method.id
      }

      expect(response).to redirect_to(payment_checkout_index_path)
    end

    it 'shows payment step' do
      # Create a simple checkout with started status first
      checkout = create(:checkout, user: user, cart: cart, status: 'started')
      checkout.update!(
        status: 'payment_info',
        shipping_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        }.to_json,
        billing_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        }.to_json,
        shipping_method: shipping_method,
        payment_method: 'credit_card'
      )

      allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
        controller.instance_variable_set(:@checkout, checkout)
      end

      get payment_checkout_index_path
      expect(response).to have_http_status(:success)
    end

    it 'shows review step' do
      # Create a checkout in review state
      checkout = create(:checkout, user: user, cart: cart, status: 'started')
      checkout.update!(
        status: 'review',
        shipping_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        }.to_json,
        billing_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        }.to_json,
        shipping_method: shipping_method,
        payment_method: 'credit_card'
      )

      allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
        controller.instance_variable_set(:@checkout, checkout)
      end

      get review_checkout_index_path
      expect(response).to have_http_status(:success)
    end

    it 'completes checkout' do
      # Create a checkout ready for completion with all required data
      checkout = create(:checkout,
        user: user,
        cart: cart,
        status: 'review',
        shipping_method: shipping_method,
        payment_method: 'credit_card',
        shipping_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        },
        billing_address_data: {
          first_name: 'John',
          last_name: 'Doe',
          address_line_1: '123 Main St',
          city: 'City',
          state_province: 'State',
          postal_code: '12345',
          country: 'US'
        }
      )

      # Log in the user manually
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }

      # Override the checkout lookup to return our specific checkout
      allow_any_instance_of(CheckoutController).to receive(:set_checkout_session) do |controller|
        puts "Mocking set_checkout_session, setting checkout to: #{checkout.inspect}"
        controller.instance_variable_set(:@checkout, checkout)
      end

      # Also mock find_checkout_session for consistency
      allow_any_instance_of(CheckoutController).to receive(:find_checkout_session).and_return(checkout)

      # Also mock current_cart to return the cart associated with this checkout
      allow_any_instance_of(CheckoutController).to receive(:current_cart).and_return(checkout.cart)

      puts "About to POST to complete_checkout_index_path"
      puts "Checkout status before: #{checkout.status}"
      puts "Cart: #{checkout.cart.inspect}"
      puts "Cart items count: #{checkout.cart.cart_items.count}"
      puts "User: #{user.inspect}"

      post complete_checkout_index_path

      puts "Response status: #{response.status}"
      puts "Response location: #{response.location}"
      puts "Flash alert: #{flash[:alert]}" if flash[:alert]
      puts "Checkout status after: #{checkout.reload.status}"

      # Check if we got a redirect (successful completion) or stayed on review (error)
      if response.status == 302
        # Success - check status changed
        expect(checkout.reload.status).to eq('completed')
      else
        # Error occurred, test should show what happened
        puts "ERROR: Response status #{response.status}"
        puts "Response body: #{response.body}" if response.status == 422
        expect(checkout.reload.status).to eq('completed')
      end
    end
  end

  describe 'AddressesController' do
    before { sign_in user }

    it 'displays user addresses' do
      address = create(:address, user: user)
      get addresses_path
      expect(response).to have_http_status(:success)
    end

    it 'creates new address' do
      expect {
        post addresses_path, params: {
          address: {
            address_type: 'shipping',
            first_name: 'John',
            last_name: 'Doe',
            address_line_1: '123 Main St',
            city: 'City',
            state_province: 'State',
            postal_code: '12345',
            country: 'US'
          }
        }
      }.to change { user.addresses.count }.by(1)
    end

    it 'updates existing address' do
      address = create(:address, user: user)
      patch address_path(address), params: {
        address: { first_name: 'Updated Name' }
      }
      expect(address.reload.first_name).to eq('Updated Name')
    end

    it 'deletes address' do
      address = create(:address, user: user)
      expect {
        delete address_path(address)
      }.to change { user.addresses.count }.by(-1)
    end
  end
end
