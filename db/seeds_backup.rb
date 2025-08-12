# db/seeds.rb
# Clear existing data
puts "Clearing existing data..."
CartItem.destroy_all
Cart.destroy_all
Product.destroy_all
Category.destroy_all
User.destroy_all

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

home_garden = Category.create!(
  name: 'Home & Garden',
  description: 'Everything for your home and garden',
  slug: 'home-garden',
  active: true,
  position: 3
)

books = Category.create!(
  name: 'Books',
  description: 'Books across all genres and categories',
  slug: 'books',
  active: true,
  position: 4
)

# Electronics subcategories
smartphones = Category.create!(
  name: 'Smartphones',
  parent: electronics,
  description: 'Latest smartphones and mobile devices',
  slug: 'smartphones',
  active: true,
  position: 1
)

laptops = Category.create!(
  name: 'Laptops',
  parent: electronics,
  description: 'Laptops and portable computers',
  slug: 'laptops',
  active: true,
  position: 2
)

headphones = Category.create!(
  name: 'Headphones',
  parent: electronics,
  description: 'Audio equipment and headphones',
  slug: 'headphones',
  active: true,
  position: 3
)

# Clothing subcategories
mens_clothing = Category.create!(
  name: "Men's Clothing",
  parent: clothing,
  description: 'Fashion and apparel for men',
  slug: 'mens-clothing',
  active: true,
  position: 1
)

womens_clothing = Category.create!(
  name: "Women's Clothing",
  parent: clothing,
  description: 'Fashion and apparel for women',
  slug: 'womens-clothing',
  active: true,
  position: 2
)

puts "Creating products..."

# Electronics products
products_data = [
  {
    name: 'iPhone 15 Pro',
    category: smartphones,
    description: 'The latest iPhone with titanium design, A17 Pro chip, and revolutionary camera system. Experience the power of professional photography in your pocket.',
    short_description: 'Latest iPhone with titanium design and A17 Pro chip',
    price: 999.99,
    compare_at_price: 1099.99,
    sku: 'IPH15PRO128',
    vendor: 'Apple',
    weight: 0.41,
    length: 6.1,
    width: 2.8,
    height: 0.32,
    track_inventory: true,
    inventory_quantity: 50,
    featured: true,
    active: true,
    position: 1
  },
  {
    name: 'MacBook Pro 14-inch',
    category: laptops,
    description: 'Supercharged by M3 Pro and M3 Max chips. Built for professionals who need extreme performance for demanding workflows.',
    short_description: 'Professional laptop with M3 Pro chip',
    price: 1999.99,
    compare_at_price: 2199.99,
    sku: 'MBP14M3PRO',
    vendor: 'Apple',
    weight: 3.5,
    length: 12.31,
    width: 8.71,
    height: 0.61,
    track_inventory: true,
    inventory_quantity: 25,
    featured: true,
    active: true,
    position: 2
  },
  {
    name: 'Sony WH-1000XM5',
    category: headphones,
    description: 'Industry-leading noise canceling with the new Integrated Processor V1. Exceptional call quality with precise voice pickup.',
    short_description: 'Premium noise-canceling headphones',
    price: 399.99,
    compare_at_price: 449.99,
    sku: 'SONY-WH1000XM5',
    vendor: 'Sony',
    weight: 0.55,
    track_inventory: true,
    inventory_quantity: 75,
    featured: true,
    active: true,
    position: 3
  },
  {
    name: 'Samsung Galaxy S24 Ultra',
    category: smartphones,
    description: 'The ultimate smartphone experience with S Pen, powerful camera system, and all-day battery life.',
    short_description: 'Flagship Android smartphone with S Pen',
    price: 1199.99,
    sku: 'SGS24ULTRA256',
    vendor: 'Samsung',
    weight: 0.51,
    track_inventory: true,
    inventory_quantity: 40,
    active: true,
    position: 4
  },
  {
    name: 'Dell XPS 13',
    category: laptops,
    description: 'Ultra-portable laptop with stunning InfinityEdge display and long battery life. Perfect for professionals on the go.',
    short_description: 'Ultra-portable laptop with InfinityEdge display',
    price: 1299.99,
    sku: 'DELL-XPS13',
    vendor: 'Dell',
    weight: 2.64,
    track_inventory: true,
    inventory_quantity: 30,
    active: true,
    position: 5
  },
  {
    name: 'Bose QuietComfort Earbuds',
    category: headphones,
    description: 'True wireless earbuds with world-class noise cancellation and rich, immersive sound.',
    short_description: 'Wireless earbuds with noise cancellation',
    price: 279.99,
    sku: 'BOSE-QCEARBUDS',
    vendor: 'Bose',
    weight: 0.19,
    track_inventory: true,
    inventory_quantity: 100,
    active: true,
    position: 6
  }
]

# Clothing products
clothing_products = [
  {
    name: 'Classic Cotton T-Shirt',
    category: mens_clothing,
    description: 'Comfortable, breathable cotton t-shirt perfect for everyday wear. Made from 100% organic cotton.',
    short_description: 'Comfortable organic cotton t-shirt',
    price: 29.99,
    sku: 'COTTON-TEE-M',
    vendor: 'EcoWear',
    weight: 0.3,
    track_inventory: true,
    inventory_quantity: 200,
    featured: true,
    active: true,
    position: 1
  },
  {
    name: 'Elegant Summer Dress',
    category: womens_clothing,
    description: 'Flowing summer dress made from sustainable materials. Perfect for casual or semi-formal occasions.',
    short_description: 'Elegant dress made from sustainable materials',
    price: 89.99,
    compare_at_price: 119.99,
    sku: 'SUMMER-DRESS-W',
    vendor: 'GreenFashion',
    weight: 0.5,
    track_inventory: true,
    inventory_quantity: 80,
    featured: true,
    active: true,
    position: 2
  }
]

# Home & Garden products
home_products = [
  {
    name: 'Smart Home Security Camera',
    category: home_garden,
    description: 'Advanced security camera with night vision, motion detection, and smartphone alerts.',
    short_description: 'Smart security camera with night vision',
    price: 199.99,
    sku: 'SMART-CAM-HD',
    vendor: 'SecureHome',
    weight: 1.2,
    track_inventory: true,
    inventory_quantity: 60,
    active: true,
    position: 1
  }
]

# Books
book_products = [
  {
    name: 'The Art of Programming',
    category: books,
    description: 'Comprehensive guide to modern programming techniques and best practices.',
    short_description: 'Comprehensive programming guide',
    price: 49.99,
    sku: 'BOOK-PROG-ART',
    vendor: 'TechPress',
    weight: 2.1,
    track_inventory: true,
    inventory_quantity: 150,
    active: true,
    position: 1
  }
]

all_products = products_data + clothing_products + home_products + book_products

all_products.each_with_index do |product_data, index|
  puts "Creating product #{index + 1}/#{all_products.length}: #{product_data[:name]}"

  product = Product.create!(product_data)

  # Add some variety to inventory levels for testing
  case index % 4
  when 0
    product.update(inventory_quantity: rand(1..5)) if product.track_inventory? # Low stock
  when 1
    product.update(inventory_quantity: 0) if product.track_inventory? && rand > 0.7 # Some out of stock
  end
end

puts "Creating carts for users..."
user.create_cart
admin.create_cart

puts "\n" + "="*50
puts "SEED DATA SUMMARY"
puts "="*50
puts "Created #{User.count} users:"
puts "  - Admin: admin@example.com (password: password123)"
puts "  - Customer: user@example.com (password: password123)"
puts ""
puts "Created #{Category.count} categories:"
Category.roots.each do |category|
  puts "  - #{category.name} (#{category.children.count} subcategories)"
end
puts ""
puts "Created #{Product.count} products across all categories"
puts "  - #{Product.where(featured: true).count} featured products"
puts "  - #{Product.where(track_inventory: true, inventory_quantity: 0).count} out of stock products"
puts "  - #{Product.where(track_inventory: true).where('inventory_quantity <= 5 AND inventory_quantity > 0').count} low stock products"
puts ""
puts "You can now:"
puts "1. Visit the homepage to see featured products"
puts "2. Browse products by category"
puts "3. Search for products"
puts "4. Log in as admin to manage products"
puts "5. Test the complete shopping experience"
puts "="*50
