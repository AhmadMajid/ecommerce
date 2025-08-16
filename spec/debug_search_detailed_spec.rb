require 'rails_helper'

RSpec.describe 'Debug Search Detailed', type: :request do
  include Warden::Test::Helpers
  
  let!(:admin_user) { create(:admin_user) }

  before do
    login_as(admin_user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  it 'debugs search functionality in detail' do
    # Create specific categories
    electronics = create(:category, name: 'Electronics and Gadgets', description: 'Tech products')
    office = create(:category, name: 'Office Supplies', description: 'Office equipment')
    
    puts "Created categories:"
    puts "- Electronics: #{electronics.name}"
    puts "- Office: #{office.name}"
    
    # Test without search first
    get admin_categories_path
    puts "\nWithout search - total categories in response: #{response.body.scan(/data-admin--bulk-target="row"/).count}"
    
    # Test with search
    get admin_categories_path, params: { search: 'Office' }
    puts "\nWith search 'Office' - total categories in response: #{response.body.scan(/data-admin--bulk-target="row"/).count}"
    puts "Response includes 'Office Supplies': #{response.body.include?('Office Supplies')}"
    puts "Response includes 'Electronics and Gadgets': #{response.body.include?('Electronics and Gadgets')}"
    
    # Check what categories exist in database
    puts "\nDatabase state:"
    Category.all.each do |cat|
      puts "- #{cat.name} (#{cat.description})"
    end
  end
end
