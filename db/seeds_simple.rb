# Clear existing data
puts "Clearing existing data..."

# Create admin user
puts "Creating admin user..."
admin = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User',
  role: 'admin',
  confirmed_at: Time.current
)

# Create regular user
puts "Creating regular user..."
user = User.create!(
  email: 'user@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'John',
  last_name: 'Doe',
  role: 'customer',
  confirmed_at: Time.current
)

puts "Creating categories..."

# Root categories
electronics = Category.create!(
  name: 'Electronics',
  description: 'Latest electronic devices and gadgets',
  slug: 'electronics',
  active: true,
  position: 1
)

clothing = Category.create!(
  name: 'Clothing',
  description: 'Fashion and apparel for all occasions',
  slug: 'clothing',
  active: true,
  position: 2
)

home = Category.create!(
  name: 'Home & Garden',
  description: 'Everything for your home and garden',
  slug: 'home-garden',
  active: true,
  position: 3
)

books = Category.create!(
  name: 'Books',
  description: 'Educational and entertainment books',
  slug: 'books',
  active: true,
  position: 4
)

# Subcategories for Electronics
smartphones = Category.create!(
  name: 'Smartphones',
  description: 'Latest smartphones and mobile devices',
  slug: 'smartphones',
  parent: electronics,
  active: true,
  position: 1
)

computers = Category.create!(
  name: 'Computers',
  description: 'Laptops, desktops, and computer accessories',
  slug: 'computers',
  parent: electronics,
  active: true,
  position: 2
)

# Subcategories for Clothing
mens = Category.create!(
  name: "Men's Clothing",
  description: 'Fashion for men',
  slug: 'mens-clothing',
  parent: clothing,
  active: true,
  position: 1
)

womens = Category.create!(
  name: "Women's Clothing",
  description: 'Fashion for women',
  slug: 'womens-clothing',
  parent: clothing,
  active: true,
  position: 2
)

puts "Creating products..."

# Electronics Products
products_data = [
  {
    name: 'iPhone 15 Pro',
    description: 'The latest iPhone with advanced features and powerful performance.',
    short_description: 'Latest iPhone with pro features',
    sku: 'PHONE-IP15-PRO',
    slug: 'iphone-15-pro',
    price: 999.99,
    compare_at_price: 1099.99,
    cost_price: 700.00,
    weight: 0.221,
    category: smartphones,
    track_inventory: true,
    inventory_quantity: 50,
    active: true,
    featured: true,
    published_at: 1.month.ago
  },
  {
    name: 'MacBook Air M3',
    description: 'Lightweight laptop with M3 chip for exceptional performance.',
    short_description: 'Powerful lightweight laptop',
    sku: 'LAPTOP-MBA-M3',
    slug: 'macbook-air-m3',
    price: 1299.99,
    compare_at_price: 1399.99,
    cost_price: 900.00,
    weight: 1.24,
    category: computers,
    track_inventory: true,
    inventory_quantity: 25,
    active: true,
    featured: true,
    published_at: 2.weeks.ago
  },
  {
    name: 'Sony WH-1000XM5 Headphones',
    description: 'Premium noise-canceling wireless headphones with exceptional sound quality.',
    short_description: 'Premium noise-canceling headphones',
    sku: 'AUDIO-SONY-XM5',
    slug: 'sony-wh-1000xm5',
    price: 399.99,
    compare_at_price: 449.99,
    cost_price: 250.00,
    weight: 0.254,
    category: electronics,
    track_inventory: true,
    inventory_quantity: 75,
    active: true,
    featured: false,
    published_at: 1.week.ago
  }
]

# Clothing Products
clothing_products = [
  {
    name: 'Organic Cotton T-Shirt',
    description: 'Comfortable organic cotton t-shirt perfect for everyday wear.',
    short_description: 'Comfortable organic cotton tee',
    sku: 'CLOTH-TEE-ORG',
    slug: 'organic-cotton-tshirt',
    price: 29.99,
    compare_at_price: 39.99,
    cost_price: 15.00,
    weight: 0.15,
    category: mens,
    track_inventory: true,
    inventory_quantity: 100,
    active: true,
    featured: false,
    published_at: 3.days.ago
  },
  {
    name: 'Eco-Friendly Jeans',
    description: 'Sustainable denim jeans made from recycled materials.',
    short_description: 'Sustainable recycled denim',
    sku: 'CLOTH-JEANS-ECO',
    slug: 'eco-friendly-jeans',
    price: 89.99,
    compare_at_price: 109.99,
    cost_price: 45.00,
    weight: 0.6,
    category: womens,
    track_inventory: true,
    inventory_quantity: 60,
    active: true,
    featured: true,
    published_at: 5.days.ago
  }
]

# Home Products
home_products = [
  {
    name: 'Smart Home Security Camera',
    description: 'WiFi-enabled security camera with motion detection and night vision.',
    short_description: 'Smart WiFi security camera',
    sku: 'HOME-CAM-SMART',
    slug: 'smart-security-camera',
    price: 149.99,
    compare_at_price: 179.99,
    cost_price: 80.00,
    weight: 0.3,
    category: home,
    track_inventory: true,
    inventory_quantity: 40,
    active: true,
    featured: false,
    published_at: 1.week.ago
  }
]

# Book Products
book_products = [
  {
    name: 'Web Development Handbook',
    description: 'Comprehensive guide to modern web development practices and technologies.',
    short_description: 'Complete web development guide',
    sku: 'BOOK-WEB-HAND',
    slug: 'web-development-handbook',
    price: 49.99,
    compare_at_price: 59.99,
    cost_price: 25.00,
    weight: 0.8,
    category: books,
    track_inventory: true,
    inventory_quantity: 30,
    active: true,
    featured: false,
    published_at: 2.days.ago
  }
]

all_products = products_data + clothing_products + home_products + book_products

all_products.each_with_index do |product_data, index|
  puts "Creating product #{index + 1}/#{all_products.length}: #{product_data[:name]}"

  Product.create!(product_data)
end

puts "Creating carts for users..."
admin.carts.create(status: 'active')
user.carts.create(status: 'active')

puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "Created #{User.count} users:"
puts "- #{User.admin.count} admin(s)"
puts "- #{User.customer.count} customer(s)"
puts ""
puts "Created #{Category.count} categories:"
puts "- #{Category.root_categories.count} root categories"
puts "- #{Category.where.not(parent_id: nil).count} subcategories"
puts ""
puts "Created #{Product.count} products:"
puts "- #{Product.featured.count} featured products"
puts "- #{Product.active.count} active products"
puts ""
puts "Created #{Cart.count} carts"
puts "="*50
puts "Sample login credentials:"
puts "Admin: admin@example.com / password123"
puts "User: user@example.com / password123"
puts "="*50
