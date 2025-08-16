require 'rails_helper'

RSpec.describe 'Debug Search Filter', type: :request do
  include Warden::Test::Helpers
  
  let!(:admin_user) { create(:admin_user) }
  let!(:category) { create(:category, name: 'Sports Equipment') }
  let!(:parent_category) { create(:category, name: 'Parent Category') }

  before do
    login_as(admin_user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  it 'debugs search filter behavior' do
    puts "Category name: #{category.name}"
    puts "Parent category name: #{parent_category.name}"
    puts "Escaped category name: #{CGI.escapeHTML(category.name)}"
    puts "Escaped parent category name: #{CGI.escapeHTML(parent_category.name)}"
    
    get admin_categories_path, params: { search: 'Parent' }
    
    puts "Response includes category name?: #{response.body.include?(CGI.escapeHTML(category.name))}"
    puts "Response includes parent category name?: #{response.body.include?(CGI.escapeHTML(parent_category.name))}"
    puts "Response includes 'Sports'?: #{response.body.include?('Sports')}"
    puts "Response includes 'Parent'?: #{response.body.include?('Parent')}"
    
    # Extract just the table content to see what categories are actually shown
    if response.body =~ /<tbody[^>]*>(.*?)<\/tbody>/m
      tbody_content = $1
      puts "Table body content preview: #{tbody_content[0..500]}"
    end
  end
end
