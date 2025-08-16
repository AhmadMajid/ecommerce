#!/usr/bin/env ruby
require_relative 'config/environment'

Rails.env = 'test'

puts "Testing CheckoutService..."

begin
  # Create test data without triggering Devise callbacks
  user_email = "test#{Time.current.to_i}@example.com"
  user = User.new(email: user_email, password: 'password', first_name: 'Test', last_name: 'User')
  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.save!
  
  cart = Cart.create!(user: user)
  
  category = Category.first || Category.create!(name: 'Test Category', slug: 'test-category')
  
  # Use existing product or create new one with unique attributes
  product = Product.first
  if product.nil?
    product = Product.create!(
      name: 'Test Product', 
      price: 10, 
      sku: "TEST#{Time.current.to_i}", 
      slug: "test-product-#{Time.current.to_i}", 
      category: category,
      inventory_quantity: 100,
      active: true
    )
  else
    # Make sure existing product is active
    product.update!(active: true, inventory_quantity: 100)
  end
  
  cart_item = CartItem.create!(cart: cart, product: product, quantity: 2)
  
  puts "Created test data:"
  puts "- User: #{user.email}"
  puts "- Cart: #{cart.id}"
  puts "- Product: #{product.name} (inventory: #{product.inventory_quantity}, active: #{product.active?})"
  puts "- Cart item quantity: #{cart_item.quantity}"
  puts "- Cart item valid?: #{cart_item.valid?}"
  puts "- Cart item errors: #{cart_item.errors.full_messages}"
  
  # Reload cart to ensure association is fresh
  cart.reload
  
  # Test the service
  service = CheckoutService.new(cart, user)
  puts "\nTesting checkout service..."
  
  # Debug cart state
  puts "Cart debug:"
  puts "- Cart blank?: #{cart.blank?}"
  puts "- Cart items count: #{cart.cart_items.count}"
  puts "- Cart items loaded: #{cart.cart_items.loaded?}"
  puts "- Cart items: #{cart.cart_items.to_a}"
  
  result = service.create_order_from_cart
  
  puts "Result: #{result.inspect}"
  puts "Errors: #{service.errors}"
  
  if result == false
    puts "Order creation failed!"
  else
    puts "Order created successfully! ID: #{result.id}"
  end
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(10)
end
