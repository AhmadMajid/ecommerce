require 'rails_helper'

RSpec.describe 'Wishlist functionality', type: :system, js: true do
  let!(:user) { create(:user) }
  let!(:product) { create(:product) }

  before do
    driven_by(:selenium_chrome_headless)
    # Sign in through the browser for system tests
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign In'

    # Wait for successful login (check for user name or logout link)
    expect(page).to have_content(user.first_name.first.upcase)
  end

  describe 'adding to wishlist from product page' do
    it 'allows user to add product to wishlist' do
      visit product_path(product)

      # Check that page loaded
      expect(page).to have_content(product.name)

      # Find the wishlist button and click it
      wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')

      # Count wishlists before
      initial_count = user.wishlists.count

      # Click the button
      wishlist_button.click

      # Wait for JavaScript to process
      sleep(2)

      # Verify the product is in the database
      user.reload
      expect(user.wishlists.count).to eq(initial_count + 1)
      expect(user.wishlists.where(product: product)).to exist
    end

    it 'allows user to remove product from wishlist' do
      # First add the product to wishlist
      create(:wishlist, user: user, product: product)

      visit product_path(product)

      # Check that page loaded
      expect(page).to have_content(product.name)

      # Find the wishlist button (should now show as added to wishlist)
      wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')

      # Wait for the button to be in the correct state (should have wishlist-active class since item is already in wishlist)
      expect(wishlist_button[:class]).to include('wishlist-active')

      # Count wishlists before
      initial_count = user.wishlists.count

      # Click to remove from wishlist
      wishlist_button.click

      # Wait for JavaScript to process and UI to update
      sleep(3)

      # Verify the product is removed from the database
      user.reload
      expect(user.wishlists.count).to eq(initial_count - 1)
      expect(user.wishlists.where(product: product)).not_to exist

      # Button should no longer have wishlist-active class
      expect(wishlist_button[:class]).not_to include('wishlist-active')
    end
  end

  describe 'wishlist page' do
    let!(:wishlist_item) { create(:wishlist, user: user, product: product) }

    it 'displays wishlist items' do
      visit wishlists_path

      expect(page).to have_content(product.name)
      expect(page).to have_content(product.price)
    end

    it 'allows user to remove items from wishlist page' do
      visit wishlists_path

      # Check that product is displayed
      expect(page).to have_content(product.name)

      # Click remove button (now using the correct add-to-cart controller)
      remove_button = find('button[data-action="click->add-to-cart#addToWishlist"]', match: :first)
      remove_button.click

      # Wait for JavaScript to process
      sleep(3)

      # Verify the product is removed
      user.reload
      expect(user.wishlists.where(product: product)).not_to exist

      # Refresh the page to see the updated list
      visit current_path
      expect(page).not_to have_content(product.name)
    end
  end

end
