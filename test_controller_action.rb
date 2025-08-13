#!/usr/bin/env ruby
require_relative 'config/environment'

puts "Testing mark_as_read controller action directly"
puts "=" * 50

# Find the pending message we created
pending_msg = ContactMessage.find_by(status: 'pending')
if pending_msg
  puts "Found pending message: #{pending_msg.id} - #{pending_msg.subject}"

  # Test the controller action logic
  puts "Before: status = #{pending_msg.status}, read_at = #{pending_msg.read_at}"

  # Simulate what the controller does
  begin
    pending_msg.mark_as_read!
    pending_msg.reload
    puts "After: status = #{pending_msg.status}, read_at = #{pending_msg.read_at}"
    puts "✅ mark_as_read! method works correctly"
  rescue => e
    puts "❌ Error: #{e.message}"
    puts e.backtrace.first(3)
  end
else
  puts "No pending message found"
end

# Check if there are any validation issues
puts "\nChecking ContactMessage model validations..."
test_msg = ContactMessage.new(status: 'pending')
puts "Valid?: #{test_msg.valid?}"
puts "Errors: #{test_msg.errors.full_messages}" unless test_msg.valid?
