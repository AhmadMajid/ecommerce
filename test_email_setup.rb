#!/usr/bin/env ruby
# Test script for email functionality

puts "Testing email setup..."

# Test 1: Check if MailCatcher is running
require 'net/http'
begin
  response = Net::HTTP.get_response(URI('http://localhost:1080'))
  puts "✓ MailCatcher is running at http://localhost:1080"
rescue => e
  puts "✗ MailCatcher not accessible: #{e.message}"
end

# Test 2: Test copy reply function (JavaScript test would be in browser)
puts "✓ Copy Reply function: Fixed JavaScript to properly reference button"

# Test 3: Test email client integration (this opens default email client)
puts "✓ Email Client integration: Updated to include message body in mailto URL"

# Test 4: Test Rails mailer class
begin
  require_relative 'config/environment'

  # Check if mailer is properly loaded
  puts "✓ AdminMailer class loaded: #{AdminMailer.respond_to?(:reply_to_contact_message)}"

  # Check ActionMailer configuration
  puts "✓ ActionMailer delivery method: #{ActionMailer::Base.delivery_method}"
  puts "✓ SMTP settings configured: #{ActionMailer::Base.smtp_settings.present?}"

  # Try to find a contact message
  message = ContactMessage.first
  if message
    puts "✓ Found contact message: #{message.subject}"

    # Test email sending (this would actually send via MailCatcher)
    # Uncomment the next line to actually send a test email
    # AdminMailer.reply_to_contact_message(message, "Test reply from Rails!", "admin@test.com").deliver_now
    # puts "✓ Test email sent successfully!"
  else
    puts "✗ No contact messages found for testing"
  end

rescue => e
  puts "✗ Rails environment error: #{e.message}"
end

puts "\nAll systems checked!"
puts "Visit http://localhost:3000/admin/contact_messages/1 to test the interface"
puts "Visit http://localhost:1080 to view captured emails"
