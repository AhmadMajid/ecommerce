require 'rails_helper'

RSpec.describe 'Admin Layout with Contact Messages', type: :view do
  let(:admin_user) { create(:admin_user) }

  before do
    # Simulate admin user authentication for view context
    allow(view).to receive(:current_user).and_return(admin_user)
    allow(view).to receive(:user_signed_in?).and_return(true)
  end

  describe 'admin sidebar navigation' do
    context 'with pending contact messages' do
      let!(:pending_messages) { create_list(:contact_message, 3, status: 'pending') }
      let!(:read_message) { create(:contact_message, :read) }

      it 'displays contact messages link with pending count badge' do
        render template: 'layouts/admin'

        expect(rendered).to have_link('Contact Messages', href: admin_contact_messages_path)
        expect(rendered).to have_css('.bg-red-100.text-red-600', text: '3')
      end

      it 'includes email icon for contact messages' do
        render template: 'layouts/admin'

        # Check for SVG email icon in the contact messages link
        expect(rendered).to have_css('svg path[d*="M3 8l7.89 4.26a2 2 0 002.22 0L21 8"]')
      end
    end

    context 'with no pending contact messages' do
      let!(:read_messages) { create_list(:contact_message, 2, :read) }
      let!(:replied_messages) { create_list(:contact_message, 1, :replied) }

      it 'displays contact messages link without badge' do
        render template: 'layouts/admin'

        expect(rendered).to have_link('Contact Messages', href: admin_contact_messages_path)
        expect(rendered).not_to have_css('.bg-red-100.text-red-600')
      end
    end

    context 'when on contact messages pages' do
      before do
        allow(view).to receive(:controller_name).and_return('contact_messages')
      end

      it 'highlights the contact messages link as active' do
        render template: 'layouts/admin'

        expect(rendered).to have_css('.bg-indigo-100.text-indigo-700')
      end
    end

    context 'when ContactMessage model is not available' do
      before do
        # Simulate case where ContactMessage might not be loaded
        hide_const('ContactMessage')
      end

      it 'gracefully handles missing ContactMessage constant' do
        expect { render template: 'layouts/admin' }.not_to raise_error
        expect(rendered).to have_link('Contact Messages', href: admin_contact_messages_path)
      end
    end

    it 'positions contact messages link correctly in sidebar order' do
      render template: 'layouts/admin'

      # Check that contact messages appears after categories and before orders
      categories_link = rendered.index('Categories')
      contact_messages_link = rendered.index('Contact Messages')
      orders_link = rendered.index('Orders')

      expect(categories_link).to be < contact_messages_link
      expect(contact_messages_link).to be < orders_link
    end

    it 'displays all expected navigation items' do
      render template: 'layouts/admin'

      expect(rendered).to have_link('Dashboard')
      expect(rendered).to have_link('Products')
      expect(rendered).to have_link('Categories')
      expect(rendered).to have_link('Contact Messages')
      expect(rendered).to have_content('Orders')
      expect(rendered).to have_content('Users')
    end
  end

  describe 'notification badge behavior' do
    it 'shows exact count of pending messages' do
      create_list(:contact_message, 5, status: 'pending')

      render template: 'layouts/admin'

      expect(rendered).to have_css('.bg-red-100.text-red-600', text: '5')
    end

    it 'does not count read messages in badge' do
      create_list(:contact_message, 2, status: 'pending')
      create_list(:contact_message, 3, status: 'read')

      render template: 'layouts/admin'

      expect(rendered).to have_css('.bg-red-100.text-red-600', text: '2')
    end

    it 'does not count replied messages in badge' do
      create_list(:contact_message, 1, status: 'pending')
      create_list(:contact_message, 4, status: 'replied')

      render template: 'layouts/admin'

      expect(rendered).to have_css('.bg-red-100.text-red-600', text: '1')
    end

    it 'does not count archived messages in badge' do
      create_list(:contact_message, 3, status: 'pending')
      create_list(:contact_message, 2, status: 'archived')

      render template: 'layouts/admin'

      expect(rendered).to have_css('.bg-red-100.text-red-600', text: '3')
    end
  end

  describe 'accessibility and usability' do
    before do
      create(:contact_message, status: 'pending')
    end

    it 'uses proper semantic HTML for navigation' do
      render template: 'layouts/admin'

      expect(rendered).to have_css('nav a[href="' + admin_contact_messages_path + '"]')
    end

    it 'includes hover states for interactive elements' do
      render template: 'layouts/admin'

      expect(rendered).to include('hover:bg-gray-100')
    end

    it 'provides visual distinction for notification badge' do
      render template: 'layouts/admin'

      expect(rendered).to have_css('.bg-red-100.text-red-600.rounded-full')
    end

    it 'maintains consistent styling with other sidebar items' do
      render template: 'layouts/admin'

      # Check that contact messages uses same classes as other nav items
      expect(rendered).to include('flex items-center px-3 py-2 text-sm font-medium rounded-md')
    end
  end
end
