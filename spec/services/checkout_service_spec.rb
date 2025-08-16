require 'rails_helper'

RSpec.describe CheckoutService do
  let(:user) { create(:user) }
  let(:cart) { create(:cart, user: user) }
  let(:product) { create(:product, price: 25.00, inventory_quantity: 10) }
  let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }
  let(:service) { described_class.new(cart, user) }

  describe '#initialize' do
    it 'sets cart and user attributes' do
      expect(service.cart).to eq(cart)
      expect(service.user).to eq(user)
      expect(service.errors).to eq([])
    end
  end

  describe '#calculate_totals' do
    context 'with empty cart' do
      let(:empty_cart) { create(:cart, user: user) }
      let(:empty_service) { described_class.new(empty_cart, user) }

      it 'returns zero totals' do
        totals = empty_service.calculate_totals
        expect(totals).to eq({
          subtotal: 0,
          tax: 0,
          shipping: 0,
          total: 0
        })
      end
    end

    context 'with items in cart' do
      it 'calculates correct totals' do
        totals = service.calculate_totals
        
        expected_subtotal = 50.00 # 2 * 25.00
        expected_tax = (expected_subtotal * 0.085).round(2) # 8.5% tax
        expected_shipping = 9.99 # Under $75, so shipping applies
        expected_total = expected_subtotal + expected_tax + expected_shipping

        expect(totals[:subtotal]).to eq(expected_subtotal)
        expect(totals[:tax]).to eq(expected_tax)
        expect(totals[:shipping]).to eq(expected_shipping)
        expect(totals[:total]).to eq(expected_total)
      end

      context 'with free shipping' do
        let(:expensive_product) { create(:product, price: 80.00, inventory_quantity: 10) }
        let(:expensive_cart_item) { create(:cart_item, cart: cart, product: expensive_product, quantity: 1) }

        before do
          expensive_cart_item
        end

        it 'applies free shipping for orders over $75' do
          totals = service.calculate_totals
          expect(totals[:shipping]).to eq(0)
        end
      end
    end
  end

  describe '#create_order_from_cart' do
    context 'with valid data' do
      let(:checkout_params) do
        {
          email: user.email,
          shipping_address: {
            first_name: 'John',
            last_name: 'Doe',
            address_line_1: '123 Main St',
            city: 'Anytown',
            state_province: 'CA',
            postal_code: '12345',
            country: 'US'
          }
        }
      end

      it 'creates an order successfully' do
        expect {
          result = service.create_order_from_cart(checkout_params)
          expect(result).to be_a(Order)
          expect(result).to be_persisted
        }.to change(Order, :count).by(1)
      end

      it 'creates order items' do
        result = service.create_order_from_cart(checkout_params)
        expect(result.order_items.count).to eq(1)
        
        order_item = result.order_items.first
        expect(order_item.product).to eq(product)
        expect(order_item.quantity).to eq(2)
        expect(order_item.unit_price).to eq(25.00)
        expect(order_item.total_price).to eq(50.00)
      end

      it 'reduces product inventory' do
        original_quantity = product.inventory_quantity
        service.create_order_from_cart(checkout_params)
        
        product.reload
        expect(product.inventory_quantity).to eq(original_quantity - 2)
      end

      it 'clears cart items' do
        service.create_order_from_cart(checkout_params)
        expect(cart.cart_items.count).to eq(0)
      end
    end

    context 'with insufficient inventory' do
      before do
        product.update!(inventory_quantity: 1)
      end

      it 'returns false and adds error' do
        result = service.create_order_from_cart
        expect(result).to be false
        expect(service.errors).to include("#{product.name} is out of stock")
      end
    end

    context 'with empty cart' do
      let(:empty_cart) { create(:cart, user: user) }
      let(:empty_service) { described_class.new(empty_cart, user) }

      it 'returns false and adds error' do
        result = empty_service.create_order_from_cart
        expect(result).to be false
        expect(empty_service.errors).to include('Cart is empty')
      end
    end
  end
end
