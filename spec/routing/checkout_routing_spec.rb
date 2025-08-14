require 'rails_helper'

RSpec.describe 'Checkout Routes', type: :routing do
  describe 'checkout coupon routes' do
    it 'routes POST /checkout/apply_coupon to checkout#apply_coupon' do
      expect(post: '/checkout/apply_coupon').to route_to(
        controller: 'checkout',
        action: 'apply_coupon'
      )
    end

    it 'routes DELETE /checkout/remove_coupon to checkout#remove_coupon' do
      expect(delete: '/checkout/remove_coupon').to route_to(
        controller: 'checkout',
        action: 'remove_coupon'
      )
    end

    it 'generates correct path helpers' do
      expect(apply_coupon_checkout_index_path).to eq('/checkout/apply_coupon')
      expect(remove_coupon_checkout_index_path).to eq('/checkout/remove_coupon')
    end
  end

  describe 'existing checkout routes' do
    it 'routes GET /checkout/new to checkout#new' do
      expect(get: '/checkout/new').to route_to(
        controller: 'checkout',
        action: 'new'
      )
    end

    it 'routes GET /checkout/shipping to checkout#shipping' do
      expect(get: '/checkout/shipping').to route_to(
        controller: 'checkout',
        action: 'shipping'
      )
    end

    it 'routes PATCH /checkout/update_shipping to checkout#update_shipping' do
      expect(patch: '/checkout/update_shipping').to route_to(
        controller: 'checkout',
        action: 'update_shipping'
      )
    end

    it 'routes GET /checkout/payment to checkout#payment' do
      expect(get: '/checkout/payment').to route_to(
        controller: 'checkout',
        action: 'payment'
      )
    end

    it 'routes PATCH /checkout/update_payment to checkout#update_payment' do
      expect(patch: '/checkout/update_payment').to route_to(
        controller: 'checkout',
        action: 'update_payment'
      )
    end

    it 'routes GET /checkout/review to checkout#review' do
      expect(get: '/checkout/review').to route_to(
        controller: 'checkout',
        action: 'review'
      )
    end

    it 'routes POST /checkout/complete to checkout#complete' do
      expect(post: '/checkout/complete').to route_to(
        controller: 'checkout',
        action: 'complete'
      )
    end

    it 'routes DELETE /checkout/:id to checkout#destroy' do
      expect(delete: '/checkout/1').to route_to(
        controller: 'checkout',
        action: 'destroy',
        id: '1'
      )
    end
  end

  describe 'path helpers' do
    it 'generates correct checkout path helpers' do
      expect(new_checkout_path).to eq('/checkout/new')
      expect(shipping_checkout_index_path).to eq('/checkout/shipping')
      expect(update_shipping_checkout_index_path).to eq('/checkout/update_shipping')
      expect(payment_checkout_index_path).to eq('/checkout/payment')
      expect(update_payment_checkout_index_path).to eq('/checkout/update_payment')
      expect(review_checkout_index_path).to eq('/checkout/review')
      expect(complete_checkout_index_path).to eq('/checkout/complete')
    end
  end
end
