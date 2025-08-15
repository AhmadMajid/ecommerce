require 'rails_helper'

RSpec.describe 'Profile Management', type: :request do
  include Warden::Test::Helpers
  
  let(:user) { create(:user) }
  
  before do
    login_as(user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  describe 'GET /profile' do
    it 'displays the user profile page' do
      get profile_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('My Profile')
      expect(response.body).to include(user.full_name)
      expect(response.body).to include(user.email)
    end

    it 'shows wishlist items when available' do
      product = create(:product)
      create(:wishlist, user: user, product: product)
      
      get profile_path
      
      expect(response.body).to include('Wishlist Items')
      expect(response.body).to include(product.name)
    end
  end

  describe 'GET /profile/edit' do
    it 'displays the edit profile form' do
      get edit_profile_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Edit Profile')
      expect(response.body).to include('Personal Information')
      expect(response.body).to include('Change Password')
      expect(response.body).to include('Notification Preferences')
    end
  end

  describe 'PATCH /profile' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          first_name: 'Updated',
          last_name: 'Name',
          phone: '+1-555-123-4567',
          date_of_birth: '1990-01-01'
        }
      end

      it 'updates the user profile' do
        patch profile_path, params: { user: valid_attributes }
        
        user.reload
        expect(user.first_name).to eq('Updated')
        expect(user.last_name).to eq('Name')
        expect(user.phone).to eq('+1-555-123-4567')
        expect(response).to redirect_to(profile_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          first_name: '',
          last_name: ''
        }
      end

      it 'does not update the user profile' do
        original_name = user.first_name
        patch profile_path, params: { user: invalid_attributes }
        
        user.reload
        expect(user.first_name).to eq(original_name)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /profile/update_password' do
    context 'with valid password parameters' do
      let(:password_attributes) do
        {
          current_password: 'password123',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'updates the user password' do
        patch update_password_profile_path, params: { user: password_attributes }
        
        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to eq('Password updated successfully!')
      end
    end

    context 'with invalid current password' do
      let(:invalid_password_attributes) do
        {
          current_password: 'wrongpassword',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'does not update the password' do
        patch update_password_profile_path, params: { user: invalid_password_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /profile/update_preferences' do
    it 'updates notification preferences' do
      patch update_preferences_profile_path, params: { 
        user: { 
          email_notifications: false, 
          marketing_emails: true 
        } 
      }
      
      user.reload
      expect(user.email_notifications).to be_falsey
      expect(user.marketing_emails).to be_truthy
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq('Preferences updated successfully!')
    end
  end

  describe 'authentication required' do
    before do
      Warden.test_reset!
    end

    it 'redirects to login when not authenticated' do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
