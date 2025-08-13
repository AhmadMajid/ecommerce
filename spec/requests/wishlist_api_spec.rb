require 'rails_helper'

RSpec.describe 'Wishlist API', type: :request do
  let!(:user) { create(:user) }
  let!(:product) { create(:product) }

  before do
    sign_in user
  end

  describe 'POST /wishlists/add/:product_id' do
    it 'adds product to wishlist and returns JSON' do
      expect {
        post "/wishlists/add/#{product.id}", headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      }.to change(user.wishlists, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('Product added to wishlist')
      expect(json_response['wishlist_count']).to eq(1)
    end

    it 'returns already exists if product already in wishlist' do
      create(:wishlist, user: user, product: product)

      post "/wishlists/add/#{product.id}", headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('already_exists')
      expect(json_response['message']).to eq('Product already in wishlist')
    end
  end

  describe 'DELETE /wishlists/remove/:product_id' do
    let!(:wishlist) { create(:wishlist, user: user, product: product) }

    it 'removes product from wishlist and returns JSON' do
      expect {
        delete "/wishlists/remove/#{product.id}", headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      }.to change(user.wishlists, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('Product removed from wishlist')
      expect(json_response['wishlist_count']).to eq(0)
    end
  end
end
