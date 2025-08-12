#!/bin/bash

echo "🧪 Testing Admin Access"
echo "======================="

cd /home/ahmad/code/AhmadMajid/ecommerce

echo ""
echo "1. Admin User Status:"
echo "--------------------"
bin/rails runner "
admin = User.find_by(email: 'admin@stylemart.com')
if admin
  puts '✅ Admin user found:'
  puts \"   Email: #{admin.email}\"
  puts \"   Role: #{admin.role}\"
  puts \"   Admin?: #{admin.admin?}\"
  puts \"   Confirmed?: #{admin.confirmed?}\"
else
  puts '❌ Admin user not found'
end
"

echo ""
echo "2. Testing Admin Controller (without auth):"
echo "-------------------------------------------"
# This will fail with authentication error, which is expected
curl -s http://localhost:3000/admin/contact_messages -w "\nHTTP Status: %{http_code}\n" | head -5

echo ""
echo "3. Contact Messages Available for Admin:"
echo "----------------------------------------"
bin/rails runner "
puts \"📊 Messages awaiting admin review:\"
puts \"Pending: #{ContactMessage.pending.count}\"
puts \"Total: #{ContactMessage.count}\"

puts \"\"
puts \"📝 Pending messages:\"
ContactMessage.pending.each do |msg|
  puts \"   • #{msg.name}: #{msg.subject} (#{msg.created_at.strftime('%m/%d %H:%M')})\"
end
"

echo ""
echo "🔐 Manual Testing Steps:"
echo "========================"
echo ""
echo "1. Open browser to: http://localhost:3000/users/sign_in"
echo "2. Login with:"
echo "   Email: admin@stylemart.com"
echo "   Password: password123"
echo "3. After login, you'll see 'Contact Messages' in user dropdown"
echo "4. Click 'Contact Messages' to access admin interface"
echo "5. Or directly visit: http://localhost:3000/admin/contact_messages"
echo ""
echo "💡 The admin interface includes:"
echo "   • List all contact messages with filtering"
echo "   • Mark messages as read/replied/archived"
echo "   • Search and bulk actions"
echo "   • Professional dashboard layout"
echo ""
echo "✅ Admin setup complete! Ready for use."
