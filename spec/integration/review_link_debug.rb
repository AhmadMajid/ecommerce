require 'rails_helper'

RSpec.describe 'Product Review Link Navigation', type: :system, js: true do
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

  describe 'review link navigation from product page' do
    it 'debugs the write review link navigation' do
      # Sign in first
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign In'

      expect(page).to have_content(user.first_name.first.upcase)

      # Visit product page
      visit product_path(product)

      puts "=== DEBUGGING REVIEW LINK NAVIGATION ==="
      puts "Product page URL: #{current_url}"
      puts "Product slug: #{product.slug}"
      puts "Expected review URL: #{new_product_review_path(product_slug: product.slug)}"

      # Try to find reviews section first
      if page.has_content?('Reviews (0)')
        puts "✓ Found 'Reviews (0)' text"

        if page.has_button?('Reviews (0)')
          puts "✓ Found 'Reviews (0)' button"
          click_button 'Reviews (0)'
          puts "✓ Clicked 'Reviews (0)' button"
          puts "After clicking Reviews tab - URL: #{current_url}"
        else
          puts "✗ No 'Reviews (0)' button found"
        end
      else
        puts "✗ No 'Reviews (0)' text found"
      end

      # Check for the review link
      if page.has_link?('Write a Review')
        puts "✓ Found 'Write a Review' link"
        review_link = find_link('Write a Review')
        puts "Link href: #{review_link[:href]}"
        puts "Link text: #{review_link.text}"
        puts "Link visible?: #{review_link.visible?}"

        # Check if it's inside a specific container
        puts "Link parent tag: #{review_link.find(:xpath, '..')[:class] rescue 'unknown'}"

        puts "About to click 'Write a Review' link..."
        click_link 'Write a Review'

        sleep 2  # Give time for navigation

        puts "After clicking 'Write a Review':"
        puts "Current URL: #{current_url}"
        puts "Current path: #{current_path}"
        puts "Expected path: #{new_product_review_path(product_slug: product.slug)}"
        puts "Page title: #{page.title}"
        puts "Has 'Write a Review' heading?: #{page.has_content?('Write a Review')}"
        puts "Has rating field?: #{page.has_content?('Rating')}"

        # Check if we're on the right page
        if current_path == new_product_review_path(product_slug: product.slug)
          puts "✓ Successfully navigated to review form"
        else
          puts "✗ Navigation failed - wrong page"
          puts "Page body preview: #{page.body[0..500]}..."
        end

      else
        puts "✗ No 'Write a Review' link found"
        puts "Available links on page:"
        page.all('a').each do |link|
          puts "  - #{link.text} -> #{link[:href]}" if link.text.present?
        end
      end
    end
  end
end
