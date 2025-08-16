require 'rails_helper'

RSpec.describe 'Debug Search Location', type: :request do
  include Warden::Test::Helpers
  
  let!(:admin_user) { create(:admin_user) }

  before do
    login_as(admin_user, scope: :user)
  end

  after do
    Warden.test_reset!
  end

  it 'finds where Electronics text appears' do
    electronics = create(:category, name: 'Electronics and Gadgets')
    office = create(:category, name: 'Office Supplies')
    
    get admin_categories_path, params: { search: 'Office' }
    
    # Check if Electronics appears in the table body (actual results)
    if response.body =~ /<tbody[^>]*>(.*?)<\/tbody>/m
      tbody_content = $1
      puts "Electronics in table body: #{tbody_content.include?('Electronics and Gadgets')}"
    end
    
    # Check if Electronics appears in the parent category dropdown
    if response.body =~ /<select[^>]*name="parent_id"[^>]*>(.*?)<\/select>/m
      select_content = $1
      puts "Electronics in parent dropdown: #{select_content.include?('Electronics and Gadgets')}"
      puts "Parent dropdown content: #{select_content}"
    end
    
    # Check if it appears in any other select elements
    response.body.scan(/<select[^>]*>(.*?)<\/select>/m).each_with_index do |match, i|
      if match[0].include?('Electronics and Gadgets')
        puts "Electronics found in select element #{i}: #{match[0][0..200]}"
      end
    end
  end
end
