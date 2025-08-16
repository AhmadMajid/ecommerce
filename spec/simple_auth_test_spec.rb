require 'rails_helper'

RSpec.describe 'Simple Authentication Test', type: :request do
  let!(:admin_user) { create(:admin_user) }
  
  it 'admin user exists' do
    puts "Admin user created: #{admin_user.inspect}"
    expect(admin_user).to be_persisted
    expect(admin_user.email).to be_present
  end
  
  it 'can access admin path without authentication' do
    get '/admin/categories'
    # Should redirect to login since not authenticated
    expect(response).to have_http_status(:redirect)
  end
  
  it 'can sign in using post request' do
    post '/users/sign_in', params: {
      user: {
        email: admin_user.email,
        password: 'password123'
      }
    }
    expect(response).to have_http_status(:redirect)
  end
end
