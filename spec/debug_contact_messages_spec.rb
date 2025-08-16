require 'rails_helper'

# Simple test to check ContactMessage functionality
RSpec.describe 'Contact Message Debug', type: :system do
  it 'creates and counts contact messages' do
    puts "Creating contact message..."
    message = ContactMessage.create!(
      name: 'Test User',
      email: 'test@example.com',
      subject: 'Test Subject',
      message: 'This is a test message',
      status: 'pending'
    )
    
    puts "ContactMessage count: #{ContactMessage.count}"
    puts "Pending count: #{ContactMessage.where(status: 'pending').count}"
    puts "Message status: #{message.status}"
    
    expect(ContactMessage.count).to eq(1)
    expect(ContactMessage.where(status: 'pending').count).to eq(1)
  end
end
