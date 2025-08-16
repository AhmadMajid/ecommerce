require 'rails_helper'

RSpec.describe 'User Factory Debug', type: :model do
  it 'creates a regular user' do
    user = create(:user)
    expect(user).to be_persisted
    expect(user.role).to eq('customer')
    puts "User ID: #{user.id}, Role: #{user.role}, Email: #{user.email}"
  end

  it 'creates an admin user' do
    admin = create(:admin_user)
    expect(admin).to be_persisted
    expect(admin.role).to eq('admin')
    expect(admin.admin?).to be true
    puts "Admin ID: #{admin.id}, Role: #{admin.role}, Email: #{admin.email}"
  end
end
