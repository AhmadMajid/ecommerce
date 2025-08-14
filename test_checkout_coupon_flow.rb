#!/usr/bin/env ruby

puts "=== Testing Checkout Coupon Functionality ==="

# Find user and get/create cart with items
user = User.first
puts "Using user: #{user.email}"

# Use existing cart or create new one
cart = user.carts.active.first || Cart.create!(user: user, session_id: "test-checkout-#{Time.current.to_i}")

# Clear any existing items and add fresh items
cart.cart_items.destroy_all
product = Product.first

cart_item = cart.cart_items.create!(
  product: product,
  quantity: 2,
  price: product.price,
  product_name: product.name
)

cart.recalculate_totals!

puts "✅ Cart prepared with:"
puts "  - Cart ID: #{cart.id}"
puts "  - Product: #{product.name}"
puts "  - Quantity: 2"
puts "  - Subtotal: $#{cart.subtotal}"
puts "  - Total: $#{cart.total}"

# Check available coupons
coupon = Coupon.first
puts "✅ Available coupon: #{coupon.code} (#{coupon.discount_type}: #{coupon.discount_value})"

puts "\n🌐 Go to http://localhost:3000/checkout/new to test coupon application!"
puts "  1. Log in as #{user.email}"
puts "  2. Go to checkout"
puts "  3. Try applying coupon: #{coupon.code}"
