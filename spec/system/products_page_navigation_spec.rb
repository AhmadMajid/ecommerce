require 'rails_helper'

RSpec.describe 'Products Page Navigation', type: :system do
  before do
    driven_by(:rack_test)
    @category = create(:category, name: 'Electronics', active: true)
    @product = create(:product, category: @category, name: 'Smartphone', active: true, price: 599.99)
  end

  describe 'Header Navigation' do
    before { visit products_path }

    it 'has working navigation links' do
      within('nav.bg-white') do  # Use the main header nav with bg-white class
        expect(page).to have_link(href: root_path)
        expect(page).to have_content('StyleMart')

        home_link = first('a', text: 'Home')
        expect(home_link[:href]).to eq('/')

        categories_link = first('a', text: 'Categories')
        expect(categories_link[:href]).to eq('/categories')
      end
    end

    it 'highlights current Products page' do
      within('nav.bg-white') do  # Use the main header nav
        products_link = first('a', text: 'Products')
        expect(products_link[:class]).to include('text-purple-600')
      end
    end
  end

  describe 'Products Page Content' do
    before { visit products_path }

    it 'displays products' do
      expect(page).to have_content('Products')
      expect(page).to have_content(@product.name)
    end

    it 'has breadcrumb navigation' do
      within('nav.mt-4') do  # Breadcrumb nav
        expect(page).to have_link('Home', href: root_path)
        expect(page).to have_content('Products')
      end
    end

    it 'has search functionality' do
      within('.w-full.lg\\:w-64 .bg-white.rounded-lg.shadow-sm') do  # The filter sidebar specifically
        fill_in 'search', with: 'Smartphone'
        click_button 'Filter'
      end

      expect(page).to have_content(@product.name)
      expect(page.current_url).to include('search=Smartphone')
    end

    it 'has category filtering' do
      within('.w-full.lg\\:w-64 .bg-white.rounded-lg.shadow-sm') do  # The filter sidebar specifically
        select @category.name, from: 'category_id'
        click_button 'Filter'
      end

      expect(page).to have_content(@product.name)
      expect(page.current_url).to include("category_id=#{@category.id}")
    end

    it 'has price range filtering' do
      within('.w-full.lg\\:w-64 .bg-white.rounded-lg.shadow-sm') do  # The filter sidebar specifically
        fill_in 'min_price', with: '500'
        fill_in 'max_price', with: '700'
        click_button 'Filter'
      end

      expect(page).to have_content(@product.name)
      expect(page.current_url).to include('min_price=500')
      expect(page.current_url).to include('max_price=700')
    end

    it 'has working product links' do
      product_link = find_link(@product.name)
      expect(product_link[:href]).to eq("/products/#{@product.slug}")

      click_link @product.name
      expect(current_path).to eq("/products/#{@product.slug}")
    end
  end

  describe 'Footer Navigation' do
    before { visit products_path }

    it 'has working footer links' do
      within('footer') do
        about_link = find_link('About Us')
        expect(about_link[:href]).to eq('/about')

        contact_link = find_link('Contact')
        expect(contact_link[:href]).to eq('/contact')
      end
    end
  end

  describe 'Navigation Back to Homepage' do
    before { visit products_path }

    it 'can navigate back to homepage' do
      within('nav.bg-white') do  # Use the main header nav
        first('a[href="/"]').click  # Click the first (logo) link
      end
      expect(current_path).to eq('/')
    end
  end
end
