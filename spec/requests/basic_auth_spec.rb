require 'rails_helper'

RSpec.describe 'Basic authentication', type: :request do
  let(:user) { create(:user) }

  describe 'GET /' do
    it 'loads the home page' do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'User authentication' do
    it 'can create a user' do
      expect { create(:user) }.to change { User.count }.by(1)
    end

    it 'can sign in via session' do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: user.password
        }
      }
      expect(response).to redirect_to(root_path)
    end
  end
end
