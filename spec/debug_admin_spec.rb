require 'rails_helper'

RSpec.describe 'Debug Admin Contact Messages', type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    # Clear any existing deliveries
    ActionMailer::Base.deliveries.clear
    
    # Create a contact message BEFORE logging in
    @pending_message = ContactMessage.create!(
      name: 'John Doe',
      subject: 'Product Inquiry',
      email: 'john@example.com',
      message: 'This is a test message that is long enough to pass validation.',
      status: 'pending'
    )
    
    puts "Created contact message: #{@pending_message.id}, status: #{@pending_message.status}"
    puts "Total ContactMessages: #{ContactMessage.count}"
    puts "Pending ContactMessages: #{ContactMessage.where(status: 'pending').count}"

    # Use direct login_as helper from Warden for better session handling
    login_as(admin_user, scope: :user)
  end

  it 'shows pending message count badge with debugging' do
    puts "About to visit admin_root_path"
    
    # Check database state before visiting page
    puts "Before visit - Total ContactMessages: #{ContactMessage.count}"
    puts "Before visit - Pending ContactMessages: #{ContactMessage.where(status: 'pending').count}"
    
    visit admin_root_path
    
    puts "Current URL: #{current_url}"
    puts "Page title: #{page.title}"
    
    # Check database state after visiting page
    puts "After visit - Total ContactMessages: #{ContactMessage.count}" 
    puts "After visit - Pending ContactMessages: #{ContactMessage.where(status: 'pending').count}"
    
    # Check if we're on the admin page
    expect(page).to have_text("Admin Panel")
    
    # Look for the sidebar
    expect(page).to have_css('nav.admin-sidebar')
    
    within('nav.admin-sidebar') do
      puts "Looking for Contact Messages link..."
      expect(page).to have_link('Contact Messages')
      
      # Print all content in the sidebar for debugging
      puts "Sidebar content: #{page.text}"
      
      # Look for any element containing '1' 
      if page.has_text?('1')
        puts "Found text '1' in sidebar"
      else
        puts "Text '1' NOT found in sidebar"
      end
      
      # Look for the badge
      if page.has_css?('.bg-red-100')
        puts "Found .bg-red-100 element"
        puts "Badge text: #{page.find('.bg-red-100').text}"
      else
        puts ".bg-red-100 element NOT found"
      end
    end
  end
end
