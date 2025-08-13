require 'rails_helper'

RSpec.describe 'Category Filtering Bug Fix', type: :system do
  before do
    driven_by(:rack_test)

    @electronics = create(:category, name: 'Electronics', active: true)
    @clothing = create(:category, name: 'Clothing', active: true)
    @books = create(:category, name: 'Books', active: true)

    @iphone = create(:product, name: 'iPhone', category: @electronics, price: 999.99, active: true)
    @shirt = create(:product, name: 'T-Shirt', category: @clothing, price: 29.99, active: true)
    @book = create(:product, name: 'Programming Book', category: @books, price: 49.99, active: true)
  end

  describe 'Products page category filtering' do
    it 'allows changing category filters multiple times without getting stuck on previous category' do
      # Start on products index
      visit products_path

      # First filter: Select Electronics
      select 'Electronics', from: 'category_id'
      click_button 'Filter'

      # Should show only iPhone
      expect(page).to have_content('iPhone')
      expect(page).not_to have_content('T-Shirt')
      expect(page).not_to have_content('Programming Book')

      # Should still be on products path with category_id param
      expect(current_path).to eq(products_path)
      expect(page).to have_current_path(/category_id=#{@electronics.id}/)

      # Second filter: Change to Clothing
      select 'Clothing', from: 'category_id'
      click_button 'Filter'

      # Should show only T-Shirt and be on products path
      expect(page).to have_content('T-Shirt')
      expect(page).not_to have_content('iPhone')
      expect(page).not_to have_content('Programming Book')
      expect(current_path).to eq(products_path)
      expect(page).to have_current_path(/category_id=#{@clothing.id}/)

      # Third filter: Go back to All Categories
      select 'All Categories', from: 'category_id'
      click_button 'Filter'

      # Should show all products and be on products path
      expect(page).to have_content('iPhone')
      expect(page).to have_content('T-Shirt')
      expect(page).to have_content('Programming Book')
      expect(current_path).to eq(products_path)
      # Check that category_id is empty (not set to a specific category)
      expect(page).to have_current_path(/category_id=$|category_id=&/)
    end

    it 'sorts correctly after changing categories' do
      visit products_path

      # Filter by Electronics first
      select 'Electronics', from: 'category_id'
      click_button 'Filter'

      # Then change to Clothing
      select 'Clothing', from: 'category_id'
      click_button 'Filter'

      # Should be able to sort properly
      select 'Price: High to Low', from: 'sort'

      # Should still show Clothing products only
      expect(page).to have_content('T-Shirt')
      expect(page).not_to have_content('iPhone')
      expect(current_path).to eq(products_path)
    end
  end

  describe 'Category page filtering redirect' do
    it 'redirects to products index when changing category from category page' do
      # Start on a specific category page
      visit category_path(@electronics)

      # Change category filter to Clothing
      select 'Clothing', from: 'category_id'
      click_button 'Filter'

      # Should redirect to products index with new category
      expect(current_path).to eq(products_path)
      expect(page).to have_current_path(/category_id=#{@clothing.id}/)
      expect(page).to have_content('T-Shirt')
      expect(page).not_to have_content('iPhone')
    end

    it 'redirects to products index when selecting All Categories from category page' do
      # Start on a specific category page
      visit category_path(@electronics)

      # Change to All Categories
      select 'All Categories', from: 'category_id'
      click_button 'Filter'

      # Should redirect to products index showing all products
      expect(current_path).to eq(products_path)
      expect(page).to have_content('iPhone')
      expect(page).to have_content('T-Shirt')
      expect(page).to have_content('Programming Book')
    end
  end
end
