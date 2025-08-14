#!/usr/bin/env ruby

puts "=== Testing Cart Cleanup Job Setup ==="

# Test immediate execution
puts "1. Testing immediate job execution..."
CartCleanupJob.perform_now
puts "✅ Immediate execution completed"

# Test background job queuing
puts "\n2. Testing background job queuing..."
job = CartCleanupJob.perform_later
puts "✅ Job queued with ID: #{job.job_id}"

puts "\n📋 Cart Cleanup Job is configured to run:"
puts "  • Every hour at minute 30"
puts "  • Deletes empty guest carts older than 1 hour"
puts "  • Abandons guest carts with items older than 7 days"
puts "  • Abandons expired carts"

puts "\n📊 Current cart status:"
puts "Total carts: #{Cart.count}"
puts "Active carts: #{Cart.active.count}"
puts "Guest carts: #{Cart.guest_carts.count}"
puts "User carts: #{Cart.user_carts.count}"

puts "\n✅ Cart cleanup background job setup complete!"
