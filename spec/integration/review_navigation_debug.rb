require 'rails_helper'

RSpec.describe 'Review Navigation', type: :system, js: true do
  let!(:category) { create(:category, name: 'Electronics', slug: 'electronics') }
  let!(:product) { create(:product,
    name: 'Test Product',
    price: 99.99,
    compare_at_price: 129.99,
    slug: 'test-product',
    category: category
  ) }
  let!(:user) { create(:user,
    first_name: 'John',
    last_name: 'Doe',
    email: 'test@example.com',
    password: 'password123'
  ) }

  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1400])
  end

  describe 'review form navigation' do
    it 'can navigate to review form directly' do
      # Sign in first
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign In'

      expect(page).to have_content(user.first_name.first.upcase)

      # Try direct navigation to review form
      visit new_product_review_path(product_slug: product.slug)

      puts "Direct review form URL: #{current_url}"
      puts "Page title: #{page.title}"
      puts "Page content includes 'Write a Review': #{page.has_content?('Write a Review')}"
      puts "Page content includes 'Rating': #{page.has_content?('Rating')}"

      # Should see the review form
      expect(page).to have_content('Write a Review')
    end
  end
end
