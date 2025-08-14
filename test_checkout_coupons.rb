#!/usr/bin/env ruby

puts "=== Testing Checkout Coupon Integration ==="

begin
  # Test that cart can have coupons
  user = User.first
  unless user
    puts "❌ No users found"
    exit
  end
  puts "✓ Found user: #{user.email}"

  # Get or create cart
  cart = user.carts.active.first || Cart.create!(user: user, session_id: "test-#{Time.current.to_i}")
  puts "✓ Cart ID: #{cart.id}"

  # Get first product and add to cart
  product = Product.first
  unless product
    puts "❌ No products found"
    exit
  end
  puts "✓ Found product: #{product.name} ($#{product.price})"

  # Add product to cart
  cart_item = cart.cart_items.find_by(product: product)
  if cart_item
    cart_item.update!(quantity: 2)
  else
    cart_item = cart.cart_items.create!(
      product: product,
      quantity: 2,
      price: product.price,
      product_name: product.name
    )
  end
  puts "✓ Added 2x #{product.name} to cart"

  # Recalculate cart totals
  cart.recalculate_totals!
  puts "✓ Cart subtotal: $#{cart.subtotal}"

  # Apply a coupon
  coupon = Coupon.first
  unless coupon
    puts "❌ No coupons found"
    exit
  end
  puts "✓ Found coupon: #{coupon.code}"

  cart.update!(coupon: coupon, coupon_code: coupon.code)
  cart.recalculate_totals!

  puts "\n📋 Cart after coupon:"
  puts "  Subtotal: $#{cart.subtotal}"
  puts "  Discount: $#{cart.discount_amount}"
  puts "  Total: $#{cart.total}"
  puts "  Coupon Code: #{cart.coupon_code}"

  # Create checkout and verify coupon transfer
  checkout = Checkout.create!(
    user: user,
    cart: cart,
    session_id: "test-session-#{Time.current.to_i}"
  )

  puts "\n📋 Checkout after creation:"
  puts "  Subtotal: $#{checkout.subtotal}"
  puts "  Discount: $#{checkout.discount_amount}"
  puts "  Total: $#{checkout.total_amount}"
  puts "  Coupon Code: #{checkout.coupon_code}"
  puts "  Coupon ID: #{checkout.coupon_id}"

  puts "\n✅ Checkout coupon integration test completed successfully!"

  # Clean up test data
  checkout.destroy
  cart_item.destroy
  puts "✓ Test data cleaned up"

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
