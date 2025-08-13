require 'rails_helper'

RSpec.describe WishlistsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:product) { create(:product) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user
  end

  describe 'GET #index' do
    let!(:wishlist) { create(:wishlist, user: user, product: product) }
    let!(:other_user_wishlist) { create(:wishlist, product: product) }

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns current user wishlists to @wishlists' do
      get :index
      expect(assigns(:wishlists)).to include(wishlist)
      expect(assigns(:wishlists)).not_to include(other_user_wishlist)
    end

    it 'includes associated products' do
      get :index
      expect(assigns(:wishlists).first.product).to eq(product)
    end
  end

  describe 'POST #create' do
    context 'when product is not in wishlist' do
      it 'creates a new wishlist item' do
        expect {
          post :create, params: { product_id: product.id }
        }.to change(user.wishlists, :count).by(1)
      end

      it 'returns success JSON response' do
        post :create, params: { product_id: product.id }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Product added to wishlist')
        expect(json_response['wishlist_count']).to eq(1)
      end
    end

    context 'when product is already in wishlist' do
      before do
        create(:wishlist, user: user, product: product)
      end

      it 'does not create duplicate wishlist item' do
        expect {
          post :create, params: { product_id: product.id }
        }.not_to change(user.wishlists, :count)
      end

      it 'returns already_exists JSON response' do
        post :create, params: { product_id: product.id }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('already_exists')
        expect(json_response['message']).to eq('Product already in wishlist')
      end
    end

    context 'when product does not exist' do
      it 'returns not found' do
        expect {
          post :create, params: { product_id: 999999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when wishlist item exists' do
      let!(:wishlist) { create(:wishlist, user: user, product: product) }

      it 'removes the wishlist item' do
        expect {
          delete :destroy, params: { product_id: product.id }
        }.to change(user.wishlists, :count).by(-1)
      end

      it 'returns success JSON response' do
        delete :destroy, params: { product_id: product.id }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Product removed from wishlist')
        expect(json_response['wishlist_count']).to eq(0)
      end
    end

    context 'when wishlist item does not exist' do
      it 'returns error JSON response' do
        delete :destroy, params: { product_id: product.id }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Could not remove from wishlist')
      end
    end

    context 'when trying to remove another user\'s wishlist item' do
      let(:other_user) { create(:user) }
      let!(:other_wishlist) { create(:wishlist, user: other_user, product: product) }

      it 'does not remove the other user\'s wishlist item' do
        expect {
          delete :destroy, params: { product_id: product.id }
        }.not_to change(other_user.wishlists, :count)
      end
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'redirects to login for index when not authenticated' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for create when not authenticated' do
      post :create, params: { product_id: product.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to login for destroy when not authenticated' do
      delete :destroy, params: { product_id: product.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
