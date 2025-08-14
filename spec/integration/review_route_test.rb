require 'rails_helper'

RSpec.describe 'Review Route Direct Test', type: :system, js: true do
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

  it 'tests direct route access to determine redirect cause' do
    # Check authentication requirement
    puts "Testing unauthenticated access to review form..."
    visit new_product_review_path(product_slug: product.slug)
    puts "Unauthenticated URL: #{current_url}"
    puts "Unauthenticated path: #{current_path}"

    # Sign in
    puts "\nSigning in..."
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign In'

    expect(page).to have_content(user.first_name.first.upcase)
    puts "✓ Successfully signed in"

    # Test authenticated access
    puts "\nTesting authenticated access to review form..."
    visit new_product_review_path(product_slug: product.slug)
    puts "Authenticated URL: #{current_url}"
    puts "Authenticated path: #{current_path}"
    puts "Has 'Write a Review' content?: #{page.has_content?('Write a Review')}"

    # Test product page review link
    puts "\nTesting product page review link..."
    visit product_path(product)
    puts "Product page URL: #{current_url}"

    click_button 'Reviews (0)'
    puts "After clicking Reviews tab - URL: #{current_url}"

    if page.has_link?('Write a Review')
      review_link = find_link('Write a Review')
      puts "Review link href: #{review_link[:href]}"
      puts "About to click the link..."

      review_link.click

      sleep 2
      puts "After clicking - URL: #{current_url}"
      puts "After clicking - path: #{current_path}"

      # Check for redirects in the response
      puts "Response status would be available in a request spec"

    else
      puts "No 'Write a Review' link found"
    end
  end
end
