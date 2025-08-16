require 'rails_helper'

RSpec.describe 'Debug Auth Request', type: :request do
  let!(:admin_user) { create(:admin_user) }

  it 'debugs admin user creation' do
    puts "Admin user created: #{admin_user.email}"
    puts "Admin user password: password123"
    puts "Admin user role: #{admin_user.role}"
    puts "Admin user valid?: #{admin_user.valid?}"
    puts "Admin user id: #{admin_user.id}"
    puts "Admin user persisted?: #{admin_user.persisted?}"
    
    # Test that admin user was created successfully
    expect(admin_user).to be_valid
    expect(admin_user.role).to eq('admin')
    expect(admin_user).to be_persisted
    
    # Test home page access (no authentication required)
    get '/'
    expect(response.status).to eq(200)
    
    puts "Home page loaded successfully"
  end
end
