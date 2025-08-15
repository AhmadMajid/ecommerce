require 'rails_helper'

RSpec.describe Users::ProfileController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    # Mock authentication methods directly instead of using sign_in
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show
      expect(response).to be_successful
      expect(assigns(:user)).to eq(user)
    end

    it 'loads wishlist items' do
      product = create(:product)
      create(:wishlist, user: user, product: product)
      
      get :show
      expect(assigns(:wishlist_items)).to include(Wishlist.last)
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit
      expect(response).to be_successful
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:valid_attributes) { { first_name: 'Updated', last_name: 'Name' } }

      it 'updates the user' do
        patch :update, params: { user: valid_attributes }
        user.reload
        expect(user.first_name).to eq('Updated')
        expect(user.last_name).to eq('Name')
      end

      it 'redirects to profile' do
        patch :update, params: { user: valid_attributes }
        expect(response).to redirect_to(profile_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { first_name: '' } }

      it 'does not update the user' do
        original_name = user.first_name
        patch :update, params: { user: invalid_attributes }
        user.reload
        expect(user.first_name).to eq(original_name)
      end

      it 'renders edit template' do
        patch :update, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update_password' do
    context 'with valid parameters' do
      let(:password_params) do
        {
          current_password: 'password123',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'updates the password and redirects' do
        patch :update_password, params: { user: password_params }
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq('Password updated successfully!')
      end
    end
  end

  describe 'PATCH #update_preferences' do
    it 'updates preferences and redirects' do
      patch :update_preferences, params: { 
        user: { email_notifications: false, marketing_emails: true } 
      }
      
      user.reload
      expect(user.email_notifications).to be_falsey
      expect(user.marketing_emails).to be_truthy
      expect(response).to redirect_to(profile_path)
    end
  end
end
