require 'rails_helper'

RSpec.describe 'Debug ContactMessage Status', type: :system do
  it 'checks ContactMessage status handling' do
    # Create with string status
    msg1 = ContactMessage.create!(
      name: 'Test User',
      email: 'test@example.com', 
      subject: 'Test Subject',
      message: 'This is a test message that is long enough',
      status: 'pending'
    )
    
    puts "Message 1 status: #{msg1.status.inspect} (#{msg1.status.class})"
    puts "Is pending? #{msg1.pending?}"
    
    # Try different queries
    puts "Count with string: #{ContactMessage.where(status: 'pending').count}"
    puts "Count with symbol: #{ContactMessage.where(status: :pending).count}"
    puts "Unread scope count: #{ContactMessage.unread.count}"
    puts "All statuses: #{ContactMessage.pluck(:status)}"
    
    # Test the enum
    puts "Available statuses: #{ContactMessage.statuses}"
  end
end
