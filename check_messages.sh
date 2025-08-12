#!/bin/bash

echo "🔍 Contact Messages Access Guide"
echo "================================"

cd /home/ahmad/code/AhmadMajid/ecommerce

echo ""
echo "1. Total Messages Count:"
echo "------------------------"
bin/rails runner "puts ContactMessage.count"

echo ""
echo "2. View All Messages:"
echo "--------------------"
bin/rails runner "
ContactMessage.all.each_with_index do |msg, i|
  puts \"#{i+1}. ID: #{msg.id} | From: #{msg.name} | Status: #{msg.status}\"
  puts \"   Email: #{msg.email}\"
  puts \"   Subject: #{msg.subject}\"
  puts \"   Message: #{msg.message[0..100]}#{'...' if msg.message.length > 100}\"
  puts \"   Created: #{msg.created_at.strftime('%Y-%m-%d %H:%M:%S')}\"
  puts \"   ---\"
end
"

echo ""
echo "3. Pending Messages Only:"
echo "------------------------"
bin/rails runner "
pending = ContactMessage.where(status: 'pending')
puts \"📬 #{pending.count} pending message(s):\"
pending.each do |msg|
  puts \"   • #{msg.name}: #{msg.subject}\"
end
"

echo ""
echo "4. Database Connection Info:"
echo "---------------------------"
bin/rails runner "
puts \"Database: #{ActiveRecord::Base.connection.current_database}\"
puts \"Database Adapter: #{ActiveRecord::Base.connection.adapter_name}\"
puts \"Total Tables: #{ActiveRecord::Base.connection.tables.count}\"
"

echo ""
echo "💡 Access Methods:"
echo "=================="
echo "• Web Admin Interface: http://localhost:3000/admin/contact_messages"
echo "• Rails Console: bin/rails console -> ContactMessage.all"
echo "• Database Direct: psql ecommerce_app_development -c 'SELECT * FROM contact_messages;'"
echo "• This Script: ./check_messages.sh"
