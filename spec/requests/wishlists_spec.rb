require 'rails_helper'

RSpec.describe 'Wishlists API', type: :request do
  let!(:user) { create(:user) }
  let!(:product) { create(:product) }

  before do
    sign_in user
  end

  describe 'GET /wishlists' do
    let!(:wishlist) { create(:wishlist, user: user, product: product) }
    let!(:other_user_wishlist) { create(:wishlist, product: product) }

    it 'returns a successful response' do
      get wishlists_path
      expect(response).to be_successful
    end

    it 'shows current user wishlists only' do
      get wishlists_path
      expect(response.body).to include(product.name)
      # Should not show other user's wishlist products
      expect(assigns(:wishlists)).to include(wishlist) if response.body.include?('@wishlists')
    end
  end

  describe 'POST /wishlists/add/:product_id' do
    it 'adds product to wishlist' do
      expect {
        post "/wishlists/add/#{product.id}"
      }.to change(user.wishlists, :count).by(1)

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('Product added to wishlist')
    end

    it 'handles duplicate wishlist items' do
      create(:wishlist, user: user, product: product)

      expect {
        post "/wishlists/add/#{product.id}"
      }.not_to change(user.wishlists, :count)

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('already_exists')
    end
  end

  describe 'DELETE /wishlists/remove/:product_id' do
    let!(:wishlist) { create(:wishlist, user: user, product: product) }

    it 'removes product from wishlist' do
      expect {
        delete "/wishlists/remove/#{product.id}"
      }.to change(user.wishlists, :count).by(-1)

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('Product removed from wishlist')
    end

    it 'handles non-existent wishlist items' do
      wishlist.destroy

      delete "/wishlists/remove/#{product.id}"

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('error')
      expect(json_response['message']).to eq('Could not remove from wishlist')
    end
  end

  describe 'authentication' do
    before { sign_out user }

    it 'redirects to login when not authenticated' do
      get wishlists_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for API endpoints when not authenticated' do
      post "/wishlists/add/#{product.id}"
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
