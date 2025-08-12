#!/bin/bash

echo "🔧 Setting up Admin Access for Contact Messages"
echo "=============================================="

cd /home/ahmad/code/AhmadMajid/ecommerce

echo ""
echo "1. Creating Admin User..."
echo "------------------------"

bin/rails runner "
# Check if admin user already exists
admin_email = 'admin@stylemart.com'
existing_admin = User.find_by(email: admin_email)

if existing_admin
  puts '✅ Admin user already exists:'
  puts \"   Email: #{existing_admin.email}\"
  puts \"   Role: #{existing_admin.role}\"
  puts \"   Admin?: #{existing_admin.admin?}\"
else
  # Create new admin user
  admin = User.create!(
    email: admin_email,
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Admin',
    last_name: 'User',
    role: 'admin',
    confirmed_at: Time.current  # Skip email confirmation
  )

  puts '✅ Admin user created successfully:'
  puts \"   Email: #{admin.email}\"
  puts \"   Password: password123\"
  puts \"   Role: #{admin.role}\"
  puts \"   Admin?: #{admin.admin?}\"
end
"

echo ""
echo "2. Checking Admin Routes..."
echo "--------------------------"

bin/rails runner "
puts '📋 Available Admin Routes:'
puts '=========================='

# Get admin routes
admin_routes = Rails.application.routes.routes
  .select { |route| route.path.spec.to_s.start_with?('/admin') }
  .map { |route| \"#{route.verb.ljust(6)} #{route.path.spec}\" }

admin_routes.each { |route| puts \"   #{route}\" }

puts ''
puts '🎯 Contact Messages Route:'
puts '   GET    /admin/contact_messages'
"

echo ""
echo "3. Testing Contact Messages Data..."
echo "----------------------------------"

bin/rails runner "
puts '📊 Contact Messages Summary:'
puts '============================'
puts \"Total Messages: #{ContactMessage.count}\"
puts \"Pending: #{ContactMessage.pending.count}\"
puts \"Read: #{ContactMessage.read.count}\"
puts \"Replied: #{ContactMessage.replied.count}\"

puts ''
puts '📝 Recent Messages:'
ContactMessage.order(created_at: :desc).limit(3).each do |msg|
  puts \"   • #{msg.name}: #{msg.subject} (#{msg.status})\"
end
"

echo ""
echo "4. Admin Access Instructions:"
echo "============================="
echo ""
echo "🔐 Login Credentials:"
echo "   Email: admin@stylemart.com"
echo "   Password: password123"
echo ""
echo "🌐 Access Steps:"
echo "   1. Go to: http://localhost:3000/users/sign_in"
echo "   2. Login with the credentials above"
echo "   3. Visit: http://localhost:3000/admin/contact_messages"
echo ""
echo "💡 Alternative Quick Access:"
echo "   • Create a link in your main navigation"
echo "   • Bookmark the admin contact messages URL"
echo "   • Use Rails console: ContactMessage.all"
echo ""
echo "✅ Admin setup complete! You can now access contact messages."
