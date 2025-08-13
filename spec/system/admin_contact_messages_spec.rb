require 'rails_helper'

RSpec.describe 'Admin Contact Messages Interface', type: :system do
  let(:admin_user) { create(:admin_user) }
  let!(:pending_message) { create(:contact_message, name: 'John Doe', subject: 'Product Inquiry') }
  let!(:read_message) { create(:contact_message, :read, name: 'Jane Smith', subject: 'Support Request') }

  before do
    # Clear any existing deliveries
    ActionMailer::Base.deliveries.clear

    # Use direct login_as helper from Warden for better session handling
    login_as(admin_user, scope: :user)
  end

  describe 'admin sidebar navigation' do
    it 'displays contact messages link in admin sidebar' do
      visit admin_root_path

      within('nav.admin-sidebar') do
        expect(page).to have_link('Contact Messages', href: admin_contact_messages_path)
        expect(page).to have_css('svg') # Email icon
      end
    end

    it 'shows pending message count badge' do
      visit admin_root_path

      within('nav.admin-sidebar') do
        # Should show count of pending messages (1 in this case)
        expect(page).to have_css('.bg-red-100', text: '1')
      end
    end

    it 'highlights active contact messages section' do
      visit admin_contact_messages_path

      within('nav.admin-sidebar') do
        expect(page).to have_css('.bg-indigo-100') # Active state class
      end
    end
  end

  describe 'contact messages index page' do
    before do
      visit admin_contact_messages_path
    end

    it 'displays all contact messages' do
      expect(page).to have_content('Contact Messages')
      expect(page).to have_content('John Doe')
      expect(page).to have_content('Jane Smith')
      expect(page).to have_content('Product Inquiry')
      expect(page).to have_content('Support Request')
    end

    it 'shows status badges for messages' do
      expect(page).to have_css('.bg-red-100', text: 'Pending')
      expect(page).to have_css('.bg-yellow-100', text: 'Read')
    end

    it 'provides search functionality' do
      fill_in 'search', with: 'John'
      click_button 'Filter'

      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'provides status filtering' do
      select 'Pending', from: 'status'
      click_button 'Filter'

      expect(page).to have_content('John Doe')
      expect(page).not_to have_content('Jane Smith')
    end

    it 'shows bulk action controls' do
      expect(page).to have_css('input[type="checkbox"]#select-all')
      expect(page).to have_select('bulk_action')
      expect(page).to have_button('Apply', disabled: true) # Button exists but is initially disabled
    end
  end

  describe 'contact message show page' do
    before do
      visit admin_contact_message_path(pending_message)
    end

    it 'displays message details' do
      expect(page).to have_content(pending_message.name)
      expect(page).to have_content(pending_message.email)
      expect(page).to have_content(pending_message.subject)
      expect(page).to have_content(pending_message.message)
    end

    it 'shows current status' do
      # Message is automatically marked as read when show page is visited
      expect(page).to have_css('.bg-yellow-100', text: 'Read')
    end

    it 'provides status change buttons' do
      # Message is automatically marked as read, so we see "Mark as Replied" button
      expect(page).to have_link('Mark as Replied')
      expect(page).to have_link('Archive')
      expect(page).to have_link('Delete')
    end

    it 'displays quick reply section' do
      expect(page).to have_content('Quick Reply')
      expect(page).to have_css('textarea#reply-textarea')
      expect(page).to have_button('Copy Reply')
      expect(page).to have_button('Open Email Client')
      expect(page).to have_button('Send via Rails')
    end

    it 'provides email template buttons' do
      expect(page).to have_button('Thank You')
      expect(page).to have_button('Request More Info')
      expect(page).to have_button('Follow Up')
      expect(page).to have_button('Issue Resolved')
    end
  end

  describe 'email template functionality', js: true do
    before do
      visit admin_contact_message_path(pending_message)
    end

    it 'inserts template content when template button is clicked' do
      click_button 'Thank You'

      textarea_content = page.find('#reply-textarea').value
      expect(textarea_content).to include('Thank you for contacting us!')
      expect(textarea_content).to include(pending_message.name)
      expect(textarea_content).to include(pending_message.subject)
    end

    it 'shows Rails email form when Send via Rails is clicked', js: true do
      fill_in 'reply-textarea', with: 'Test reply message'
      click_button 'Send via Rails'

      expect(page).to have_css('#rails-email-form:not(.hidden)')
      expect(page).to have_field('admin_email', with: 'admin@yourstore.com')
      expect(page).to have_button('Send Email Now')

      # Wait for JavaScript to show the Cancel button and check for either version
      expect(page).to have_link('Cancel').or have_button('Cancel')
    end

    it 'can cancel Rails email form', js: true do
      fill_in 'reply-textarea', with: 'Test reply message'
      click_button 'Send via Rails'

      # Click either the link or button version of Cancel
      if page.has_button?('Cancel')
        click_button 'Cancel'
        # JavaScript cancel should hide the form
        expect(page).to have_css('#rails-email-form.hidden')
      else
        click_link 'Cancel'
        # Link cancel reloads the page, form should be hidden by default
        expect(page).not_to have_css('#rails-email-form:not(.hidden)')
      end
    end
  end

  describe 'sending emails via Rails' do
    before do
      visit admin_contact_message_path(pending_message)
    end

    it 'sends email successfully', js: true do
      fill_in 'reply-textarea', with: 'Thank you for your inquiry!'
      click_button 'Send via Rails'

      within '#rails-email-form' do
        fill_in 'admin_email', with: 'test-admin@example.com'
        click_button 'Send Email Now'
      end

      expect(page).to have_content('Reply sent successfully!')
      expect(ActionMailer::Base.deliveries.count).to eq(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(pending_message.email)
      expect(email.from).to include('test-admin@example.com')
      expect(email.subject).to eq("Re: #{pending_message.subject}")
    end

    it 'handles blank reply content', js: true do
      click_button 'Send via Rails'

      # Handle the JavaScript alert
      alert_text = accept_alert
      expect(alert_text).to eq('Please enter a reply message first')
      # Form should remain visible after validation error
      expect(page).not_to have_css('#rails-email-form.hidden')
    end
  end

  describe 'status management' do
    it 'automatically marks pending message as read when viewed' do
      test_pending_message = create(:contact_message, :pending)
      expect(test_pending_message.status).to eq('pending')

      visit admin_contact_message_path(test_pending_message)

      # Message should be automatically marked as read when viewed
      expect(test_pending_message.reload.status).to eq('read')
      expect(page).to have_css('.bg-yellow-100', text: 'Read')
    end

    it 'marks message as replied when clicked' do
      read_message = create(:contact_message, :read)
      visit admin_contact_message_path(read_message)
      click_link 'Mark as Replied'

      expect(page).to have_content('Message marked as replied')
      expect(read_message.reload.status).to eq('replied')
    end

    it 'archives message when clicked' do
      visit admin_contact_message_path(pending_message)
      click_link 'Archive'

      expect(page).to have_content('Message archived')
      expect(pending_message.reload.status).to eq('archived')
    end
  end

  describe 'bulk actions' do
    let!(:additional_messages) { create_list(:contact_message, 2) }

    before do
      visit admin_contact_messages_path
    end

    it 'performs bulk mark as read action', js: true do
      # Select all checkboxes
      check 'select-all'

      select 'Mark as Read', from: 'bulk_action'

      # Confirm the action
      accept_confirm do
        click_button 'Apply'
      end

      expect(page).to have_content('messages marked as read')
    end

    it 'shows error when no messages selected', js: true do
      select 'Mark as Read', from: 'bulk_action'

      # The Apply button should be disabled when no checkboxes are selected
      expect(page).to have_button('Apply', disabled: true)

      # Force click the disabled button to test server-side validation
      page.execute_script("document.getElementById('bulk-apply-btn').disabled = false")
      click_button 'Apply'

      # Handle the JavaScript alert
      alert_text = accept_alert
      expect(alert_text).to include('Please select at least one message')
    end
  end

  describe 'navigation between messages' do
    let!(:message1) { create(:contact_message, name: 'First Message') }
    let!(:message2) { create(:contact_message, name: 'Second Message') }

    it 'shows navigation between messages' do
      # Visit the middle message (message1) which should have both prev and next
      visit admin_contact_message_path(message1)

      expect(page).to have_link('Previous Message')
      expect(page).to have_link('Next Message')
    end
  end
end
