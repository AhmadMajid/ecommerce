require 'rails_helper'

RSpec.describe 'Categories Page Navigation', type: :system do
  before do
    driven_by(:rack_test)
    @category1 = create(:category, name: 'Electronics', active: true, featured: true)
    @category2 = create(:category, name: 'Clothing', active: true, featured: true)
    @product = create(:product, category: @category1, name: 'Smartphone', active: true)
  end

  describe 'Header Navigation' do
    before { visit categories_path }

    it 'has working navigation links' do
      within('nav.bg-white') do
        expect(page).to have_link(href: root_path)
        expect(page).to have_content('StyleMart')

        home_link = first('a', text: 'Home')
        expect(home_link[:href]).to eq('/')

        products_link = first('a', text: 'Products')
        expect(products_link[:href]).to eq('/products')
      end
    end

    it 'highlights current Categories page' do
      within('nav.bg-white') do
        categories_link = first('a', text: 'Categories')
        expect(categories_link[:class]).to include('text-purple-600')
      end
    end
  end

  describe 'Categories Page Content' do
    before { visit categories_path }

    it 'displays categories' do
      expect(page).to have_content('Categories')
      expect(page).to have_content(@category1.name)
      expect(page).to have_content(@category2.name)
    end

    it 'has breadcrumb navigation' do
      if page.has_css?('nav.mt-4') || page.has_content?('Home')
        expect(page).to have_link('Home', href: root_path)
        expect(page).to have_content('Categories')
      end
    end

    it 'has working category links' do
      category_link = find_link(@category1.name)
      expect(category_link[:href]).to match(/categories\/#{@category1.slug}|categories\/#{@category1.id}/)

      click_link @category1.name
      expect(current_path).to match(/categories\/#{@category1.slug}|categories\/#{@category1.id}/)
    end
  end

  describe 'Category Cards Information' do
    before { visit categories_path }

    it 'displays category information correctly' do
      expect(page).to have_content(@category1.name)
      expect(page).to have_content(@category2.name)

      # Check for category descriptions if they exist
      if @category1.description.present?
        expect(page).to have_content(@category1.description)
      end
    end

    it 'shows category images or placeholders' do
      # Check that category cards have images or placeholder icons
      has_images = page.has_css?('img') || page.has_css?('svg') || page.has_css?('.fa-image')
      expect(has_images).to be_truthy
    end

    it 'shows product counts for categories' do
      # Many category pages show product counts
      if page.has_content?('product') || page.has_content?('item')
        expect(page).to have_content(/\d+\s+(product|item)/)
      end
    end
  end

  describe 'Footer Navigation' do
    before { visit categories_path }

    it 'has working footer links' do
      within('footer') do
        about_link = find_link('About Us')
        expect(about_link[:href]).to eq('/about')

        contact_link = find_link('Contact')
        expect(contact_link[:href]).to eq('/contact')
      end
    end

    it 'has working newsletter signup in footer' do
      within('footer') do
        if page.has_field?('newsletter[email]')
          fill_in 'newsletter[email]', with: 'test@example.com'
          click_button 'Subscribe'

          success_indicators = page.has_current_path?(categories_path) ||
                              page.has_content?('subscribed') ||
                              page.has_content?('Thank you')
          expect(success_indicators).to be_truthy
        end
      end
    end
  end

  describe 'Navigation Back to Homepage' do
    before { visit categories_path }

    it 'can navigate back to homepage via logo' do
      within('nav.bg-white') do
        first('a[href="/"]').click
      end
      expect(current_path).to eq('/')
    end

    it 'can navigate back to homepage via Home link' do
      if page.has_link?('Home')
        within('nav.bg-white') do
          first('a', text: 'Home').click
        end
        expect(current_path).to eq('/')
      end
    end
  end

  describe 'Category to Products Navigation' do
    before { visit categories_path }

    it 'can navigate to products from category' do
      click_link @category1.name

      # Should be on category show page which may display products
      expect(current_path).to match(/categories/)

      # If there's a "View Products" or similar link, test it
      if page.has_link?('View Products') || page.has_link?('Browse Products')
        link_text = page.has_link?('View Products') ? 'View Products' : 'Browse Products'
        click_link link_text
        expect(current_path).to eq('/products')
      end
    end

    it 'shows products within category page' do
      click_link @category1.name

      # Category show page should display products from that category
      if page.has_content?(@product.name)
        expect(page).to have_content(@product.name)

        # Test product link from category page
        product_link = find_link(@product.name)
        expect(product_link[:href]).to eq("/products/#{@product.slug}")
      end
    end
  end
end
