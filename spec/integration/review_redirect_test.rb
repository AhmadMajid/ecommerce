require 'rails_helper'

RSpec.describe 'Review Redirect Investigation', type: :system, js: true do
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

  it 'replicates the exact steps from the failing test' do
    # Replicate the EXACT steps from the failing test

    # Visit product page as guest first (like original test)
    visit product_path(product)
    expect(page).to have_content(product.name)

    # Sign in (like original test)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign In'

    expect(page).to have_content(user.first_name.first.upcase)

    # Go back to product page (like original test)
    visit product_path(product)

    # Add to wishlist first (like original test - this might affect state)
    wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')
    wishlist_button.click
    expect(page).to have_content('Product added to wishlist', wait: 10)

    puts "After wishlist addition - URL: #{current_url}"
    puts "User ID: #{user.id}"
    puts "Product ID: #{product.id}"
    puts "Product slug: #{product.slug}"

    # Now try the review flow
    click_button 'Reviews (0)'
    puts "After clicking Reviews tab - URL: #{current_url}"

    if page.has_link?('Write a Review')
      review_link = find_link('Write a Review')
      puts "Review link href: #{review_link[:href]}"
      puts "Review link class: #{review_link[:class]}"
      puts "Review link target: #{review_link[:target]}"
      puts "Review link data-turbo: #{review_link['data-turbo']}"

      # Check if this is a regular link or has special behavior
      if review_link['data-turbo'] == 'false' || review_link['target'] == '_blank'
        puts "Link has special navigation behavior"
      end

      click_link 'Write a Review'

      sleep 2
      puts "After clicking Write a Review - URL: #{current_url}"
      puts "Current path: #{current_path}"

      if current_path == '/'
        puts "REDIRECTED TO HOME PAGE!"
        puts "Let's check server logs or errors..."
        puts "Page title: #{page.title}"
        puts "Page has error message?: #{page.has_content?('error') || page.has_content?('Error')}"
        puts "Page has alert message?: #{page.has_content?('alert') || page.has_content?('Alert')}"

        # Try direct navigation to see if it works
        puts "Trying direct navigation..."
        visit new_product_review_path(product_slug: product.slug)
        puts "Direct navigation URL: #{current_url}"
        puts "Direct navigation works?: #{page.has_content?('Write a Review')}"
      end

    else
      puts "No 'Write a Review' link found"
    end
  end
end
