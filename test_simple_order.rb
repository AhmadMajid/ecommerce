require_relative 'config/environment'

puts "Testing OrderItem creation..."

# Create test data
user = User.create!(
  email: "test#{rand(1000000000)}@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Test",
  last_name: "User",
  phone: "1234567890"
)

cart = Cart.create!(user: user, session_id: SecureRandom.hex(16))

product = Product.create!(
  name: "Test Product",
  description: "Test description",
  price: 10.00,
  sku: "TEST-#{rand(100000)}",
  inventory_quantity: 100,
  active: true,
  category: Category.first || Category.create!(name: "Test Category", slug: "test-category")
)

cart_item = cart.cart_items.create!(
  product: product,
  quantity: 2,
  price: product.price,
  product_name: product.name
)

# Create a basic order
order = Order.create!(
  user: user,
  email: user.email,
  status: 'pending',
  currency: 'USD',
  subtotal: cart.subtotal,
  tax_amount: 0.0,
  shipping_amount: 5.0,
  total_amount: cart.subtotal + 5.0,
  billing_address: {
    first_name: "Test",
    last_name: "User",
    address1: "123 Test St",
    city: "Test City",
    state: "TS",
    zip: "12345",
    country: "US"
  },
  shipping_address: {
    first_name: "Test",
    last_name: "User", 
    address1: "123 Test St",
    city: "Test City",
    state: "TS",
    zip: "12345",
    country: "US"
  }
)

puts "Created order: #{order.id}"

# Test order item creation directly
puts "\nTesting order item creation:"
cart_item = cart.cart_items.first
product = cart_item.product

begin
  order_item = order.order_items.create!(
    product: product,
    product_variant: cart_item.respond_to?(:product_variant) ? cart_item.product_variant : nil,
    product_name: product.name,
    product_sku: product.sku,
    variant_title: cart_item.respond_to?(:product_variant) ? cart_item.product_variant&.title : nil,
    variant_sku: cart_item.respond_to?(:product_variant) ? cart_item.product_variant&.sku : nil,
    quantity: cart_item.quantity,
    unit_price: product.price,
    total_price: cart_item.quantity * product.price,
    taxable: product.taxable?
  )
  puts "✅ OrderItem created successfully: #{order_item.id}"
  puts "- Product: #{order_item.product_name}"
  puts "- Quantity: #{order_item.quantity}"
  puts "- Unit price: #{order_item.unit_price}"
  puts "- Total price: #{order_item.total_price}"
  puts "- Product variant: #{order_item.product_variant || 'nil'}"
  
  puts "\n✅ SUCCESS: Core order creation logic is working!"
rescue => e
  puts "❌ OrderItem creation failed: #{e.message}"
  puts "Full error: #{e.class}: #{e.message}"
end

puts "\nOrder items count: #{order.order_items.count}"
