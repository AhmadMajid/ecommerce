#!/usr/bin/env ruby

puts "=== Testing Checkout Coupon Application ==="

# Simulate applying coupon during checkout
user = User.first
cart = user.carts.active.first

puts "Initial cart state:"
puts "  Subtotal: $#{cart.subtotal}"
puts "  Discount: $#{cart.discount_amount}"
puts "  Total: $#{cart.total}"
puts "  Coupon: #{cart.coupon_code || 'none'}"

# Apply coupon to cart (simulating checkout coupon application)
coupon_code = "SAVE10"
result = cart.apply_coupon(coupon_code)

puts "\nAfter applying coupon '#{coupon_code}':"
puts "  Success: #{result[:success]}"
puts "  Message: #{result[:message]}"

if result[:success]
  cart.reload
  puts "  Subtotal: $#{cart.subtotal}"
  puts "  Discount: $#{cart.discount_amount}"
  puts "  Total: $#{cart.total}"
  puts "  Coupon: #{cart.coupon_code}"

  # Test checkout total calculation
  checkout = Checkout.create!(
    user: user,
    cart: cart,
    session_id: "test-#{Time.current.to_i}",
    status: 'started'
  )

  puts "\nCheckout totals:"
  puts "  Subtotal: $#{checkout.subtotal}"
  puts "  Discount: $#{checkout.discount_amount}"
  puts "  Total: $#{checkout.total_amount}"
  puts "  Coupon Code: #{checkout.coupon_code}"
  puts "  Coupon ID: #{checkout.coupon_id}"
end

puts "\n✅ Checkout coupon functionality test complete!"
