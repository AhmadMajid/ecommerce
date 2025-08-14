require 'rails_helper'

RSpec.describe 'Star Rating Interaction', type: :system, js: true do
  let!(:user) { create(:user,
    first_name: 'John',
    last_name: 'Doe',
    email: 'test@example.com',
    password: 'password123'
  ) }
  let!(:product) { create(:product,
    name: 'Test Product',
    slug: 'test-product'
  ) }
  let!(:review) { create(:review, user: user, product: product, rating: 3, title: 'Good product', content: 'It works well') }

  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1400])
    # Sign in through the browser for system tests
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Sign In'
    expect(page).to have_content(user.first_name.first.upcase)
  end

  describe 'new review form star rating' do
    it 'highlights all stars up to hovered star' do
      visit new_product_review_path(product_slug: product.slug)

      # Initially all stars should be gray
      expect(page).to have_css('.rating-star.text-gray-300', count: 5)
      expect(page).to have_css('.rating-star.text-yellow-400', count: 0)

      # Hover over 3rd star should highlight stars 1, 2, and 3
      find('.rating-star[data-rating="3"]').hover
      sleep 0.5 # Give time for JavaScript

      # Check that stars 1-3 are highlighted
      expect(page).to have_css('.rating-star.text-yellow-400', count: 3)
      expect(page).to have_css('.rating-star.text-gray-300', count: 2)

      # Click on 4th star should select 4 stars
      find('.rating-star[data-rating="4"]').click
      sleep 0.5

      # Check that stars 1-4 are highlighted and stay highlighted
      expect(page).to have_css('.rating-star.text-yellow-400', count: 4)
      expect(page).to have_css('.rating-star.text-gray-300', count: 1)

      # Move mouse away and stars should remain selected
      find('h1').hover # Move mouse to heading
      sleep 0.5

      expect(page).to have_css('.rating-star.text-yellow-400', count: 4)
      expect(page).to have_css('.rating-star.text-gray-300', count: 1)
    end
  end

  describe 'edit review form star rating' do
    it 'shows current rating and allows changing with proper highlighting' do
      visit edit_product_review_path(product_slug: product.slug, id: review.id)

      # Should show current rating (3 stars)
      expect(page).to have_css('.rating-star.text-yellow-400', count: 3)
      expect(page).to have_css('.rating-star.text-gray-300', count: 2)

      # Hover over 5th star should highlight all 5
      find('.rating-star[data-rating="5"]').hover
      sleep 0.5

      expect(page).to have_css('.rating-star.text-yellow-400', count: 5)
      expect(page).to have_css('.rating-star.text-gray-300', count: 0)

      # Click on 5th star should select it
      find('.rating-star[data-rating="5"]').click
      sleep 0.5

      # Should remain at 5 stars
      expect(page).to have_css('.rating-star.text-yellow-400', count: 5)

      # Move mouse away - should stay at 5 stars
      find('h1').hover
      sleep 0.5

      expect(page).to have_css('.rating-star.text-yellow-400', count: 5)
      expect(page).to have_css('.rating-star.text-gray-300', count: 0)
    end

    it 'works after Turbo navigation from product page' do
      # Start from product page (typical user flow)
      visit product_path(product)

      # Navigate to Reviews tab
      click_button 'Reviews (1)'

      # Click Edit link (this will use Turbo navigation)
      click_link 'Edit'

      # Verify we're on the edit page
      expect(page).to have_content('Edit Your Review')

      # Star rating should work immediately after Turbo navigation
      # Should show current rating (3 stars)
      expect(page).to have_css('.rating-star.text-yellow-400', count: 3)
      expect(page).to have_css('.rating-star.text-gray-300', count: 2)

      # Hover should work immediately
      find('.rating-star[data-rating="4"]').hover
      sleep 0.5

      expect(page).to have_css('.rating-star.text-yellow-400', count: 4)
      expect(page).to have_css('.rating-star.text-gray-300', count: 1)

      # Click should work immediately
      find('.rating-star[data-rating="4"]').click
      sleep 0.5

      expect(page).to have_css('.rating-star.text-yellow-400', count: 4)
      expect(page).to have_css('.rating-star.text-gray-300', count: 1)
    end
  end
end
