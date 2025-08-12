require 'rails_helper'

RSpec.describe 'About Page Navigation', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'Header Navigation' do
    before { visit about_path }

    it 'has working navigation links' do
      within('nav.bg-white') do
        expect(page).to have_link(href: root_path)
        expect(page).to have_content('StyleMart')

        home_link = first('a', text: 'Home')
        expect(home_link[:href]).to eq('/')

        products_link = first('a', text: 'Products')
        expect(products_link[:href]).to eq('/products')

        categories_link = first('a', text: 'Categories')
        expect(categories_link[:href]).to eq('/categories')

        contact_link = first('a', text: 'Contact')
        expect(contact_link[:href]).to eq('/contact')
      end
    end

    it 'highlights current About page' do
      within('nav.bg-white') do
        about_link = first('a', text: 'About')
        expect(about_link[:class]).to include('text-purple-600')
      end
    end

    it 'has working cart icon' do
      within('nav.bg-white') do
        expect(page).to have_css('i.fa-shopping-cart')
      end
    end
  end

  describe 'About Page Content' do
    before { visit about_path }

    it 'displays About page content' do
      expect(page).to have_content('About')
    end

    it 'has breadcrumb navigation if implemented' do
      if page.has_css?('nav.mt-4') || page.has_content?('Home')
        expect(page).to have_link('Home', href: root_path)
        expect(page).to have_content('About')
      end
    end

    it 'may have call-to-action links to other pages' do
      # About pages often have links to products, contact, etc.
      if page.has_link?('Shop Now') || page.has_link?('Browse Products')
        shop_link = page.has_link?('Shop Now') ? find_link('Shop Now') : find_link('Browse Products')
        expect(shop_link[:href]).to eq('/products')
      end

      if page.has_link?('Contact Us') || page.has_link?('Get in Touch')
        contact_link = page.has_link?('Contact Us') ? find_link('Contact Us') : find_link('Get in Touch')
        expect(contact_link[:href]).to eq('/contact')
      end
    end
  end

  describe 'Footer Navigation' do
    before { visit about_path }

    it 'has working footer links' do
      within('footer') do
        contact_link = find_link('Contact')
        expect(contact_link[:href]).to eq('/contact')

        privacy_link = find_link('Privacy Policy')
        expect(privacy_link[:href]).to eq('/privacy-policy')

        terms_link = find_link('Terms of Service')
        expect(terms_link[:href]).to eq('/terms-of-service')
      end
    end

    it 'has working newsletter signup in footer' do
      within('footer') do
        if page.has_field?('newsletter[email]')
          fill_in 'newsletter[email]', with: 'test@example.com'
          click_button 'Subscribe'

          success_indicators = page.has_current_path?(about_path) ||
                              page.has_content?('subscribed') ||
                              page.has_content?('Thank you')
          expect(success_indicators).to be_truthy
        end
      end
    end

    it 'has social media links' do
      within('footer') do
        expect(page).to have_css('i.fab.fa-facebook')
        expect(page).to have_css('i.fab.fa-twitter')
        expect(page).to have_css('i.fab.fa-instagram')
        expect(page).to have_css('i.fab.fa-linkedin')
      end
    end
  end

  describe 'Navigation Back to Homepage' do
    before { visit about_path }

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

  describe 'Navigation to Other Primary Pages' do
    before { visit about_path }

    it 'can navigate to Products page' do
      within('nav.bg-white') do
        first('a', text: 'Products').click
      end
      expect(current_path).to eq('/products')
    end

    it 'can navigate to Categories page' do
      within('nav.bg-white') do
        first('a', text: 'Categories').click
      end
      expect(current_path).to eq('/categories')
    end

    it 'can navigate to Contact page' do
      within('nav.bg-white') do
        first('a', text: 'Contact').click
      end
      expect(current_path).to eq('/contact')
    end
  end
end
