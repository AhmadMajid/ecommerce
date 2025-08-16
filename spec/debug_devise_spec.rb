require 'rails_helper'

RSpec.describe 'Devise Authentication Debug', type: :controller do
  controller(ApplicationController) do
    def index
      render plain: 'success'
    end
  end

  let!(:admin_user) { create(:admin_user) }

  it 'can sign in an admin user' do
    puts "Admin user: #{admin_user.inspect}"
    puts "Admin user ID: #{admin_user.id}"
    puts "Admin user email: #{admin_user.email}"
    puts "Admin user role: #{admin_user.role}"
    puts "Admin user persisted: #{admin_user.persisted?}"
    
    expect(admin_user).to be_persisted
    expect(admin_user.role).to eq('admin')
    
    sign_in admin_user
    get :index
    expect(response).to have_http_status(:success)
  end
end
