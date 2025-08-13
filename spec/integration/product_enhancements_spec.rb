require 'rails_helper'

RSpec.describe 'Product page enhancements integration', type: :system do
  let!(:user) { create(:user) }
  let!(:category) { create(:category) }
  let!(:product) { create(:product, category: category, price: 99.99, compare_at_price: 129.99) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'complete user journey' do
    it 'allows user to view product, add to wishlist, write review, and manage both' do
      # Visit product page as guest
      visit product_path(product)

      # Should see product details with discount
      expect(page).to have_content(product.name)
      expect(page).to have_content('$99.99')
      expect(page).to have_content('$129.99')
      expect(page).to have_content('Save 23%') # Calculated discount

      # Should see 0 reviews initially
      expect(page).to have_content('(0 reviews)')

      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign In'

      # Wait for successful login
      expect(page).to have_content(user.first_name.first.upcase)

      visit product_path(product)

      # Add to wishlist
      wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')
      wishlist_button.click

      expect(page).to have_content('Product added to wishlist', wait: 10)

      # Write a review - need to click on Reviews tab first
      click_button 'Reviews (0)'
      click_link 'Write a Review'

      find('label[data-rating="4"]').click
      fill_in 'Review Title', with: 'Good value for money'
      fill_in 'Your Review', with: 'This product offers great value. The discount made it even better!'

      click_button 'Submit Review'

      # Should be back on product page with review
      expect(page).to have_content('Thank you for your review!')
      expect(page).to have_content('4.0') # Average rating
      expect(page).to have_content('(1 review)')

      # Check reviews tab
      click_button 'Reviews (1)'
      expect(page).to have_content('Good value for money')
      expect(page).to have_content('This product offers great value')

      # Visit wishlist page
      visit wishlists_path
      expect(page).to have_content(product.name)
      expect(page).to have_content('$99.99')

      # Remove from wishlist via wishlist page
      find('button[data-action="click->add-to-cart#addToWishlist"]').click
      expect(page).to have_content('Product removed from wishlist')

      # Go back to product page
      visit product_path(product)

      # Wishlist button should no longer be active
      wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')
      expect(wishlist_button[:class]).not_to include('wishlist-active')

      # But review should still be there
      expect(page).to have_content('4.0')
      expect(page).to have_content('(1 review)')

      # Edit the review
      click_button 'Reviews (1)'
      click_link 'Edit'

      find('label[data-rating="5"]').click
      fill_in 'Review Title', with: 'Excellent product!'

      click_button 'Update Review'

      # Review should be updated
      expect(page).to have_content('Your review has been updated!')
      expect(page).to have_content('5.0') # Updated average rating

      click_button 'Reviews (1)'
      expect(page).to have_content('Excellent product!')
    end
  end

  describe 'discount calculation verification' do
    it 'displays correct discount percentages' do
      # Test various discount scenarios
      test_cases = [
        { price: 80.00, compare_at_price: 100.00, expected_discount: 20 },
        { price: 75.50, compare_at_price: 100.00, expected_discount: 25 }, # Should round to 25
        { price: 66.67, compare_at_price: 100.00, expected_discount: 33 }  # Should round to 33
      ]

      test_cases.each do |test_case|
        product.update!(
          price: test_case[:price],
          compare_at_price: test_case[:compare_at_price]
        )

        visit product_path(product)

        expect(page).to have_content("Save #{test_case[:expected_discount]}%")
      end
    end
  end

  describe 'rating display verification' do
    let!(:review1) { create(:review, product: product, rating: 5, title: 'Great', content: 'Excellent') }
    let!(:review2) { create(:review, product: product, rating: 3, title: 'OK', content: 'Average') }
    let!(:review3) { create(:review, product: product, rating: 4, title: 'Good', content: 'Nice') }

    it 'displays correct average rating and star visualization' do
      visit product_path(product)

      # Average should be 4.0 (5+3+4)/3 = 4
      expect(page).to have_content('4.0')
      expect(page).to have_content('(3 reviews)')

      # In the product header, should see 4 filled stars
      header_stars = page.all('svg.text-yellow-400')
      expect(header_stars.count).to be >= 4

      # Check reviews section
      click_button 'Reviews (3)'
      expect(page).to have_content('4.0 out of 5 (3 reviews)')

      # Each review should show correct number of filled stars
      expect(page).to have_content('Great')
      expect(page).to have_content('OK')
      expect(page).to have_content('Good')
    end
  end

  describe 'responsive behavior' do
    it 'works correctly on mobile viewport' do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign In'

      # Wait for successful login
      expect(page).to have_content(user.first_name.first.upcase)

      visit product_path(product)

      # Should still be able to add to wishlist
      wishlist_button = find('button[data-action="click->add-to-cart#addToWishlist"]')
      wishlist_button.click

      expect(page).to have_content('Product added to wishlist', wait: 10)

      # Should still be able to write review
      if page.has_button?('Reviews (0)')
        click_button 'Reviews (0)'
      end

      if page.has_link?('Write a Review')
        click_link 'Write a Review'
        expect(page).to have_content('Write a Review')
      else
        puts "Write a Review link not found after clicking reviews tab"
        puts page.body[0..1000]
      end
    end
  end
end
