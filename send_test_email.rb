require_relative 'config/environment'

puts "Sending test email..."

message = ContactMessage.first
if message
  reply_text = "Thank you for your inquiry about our winter collection! We have received your message and will get back to you with detailed information about our products, pricing, and availability.\n\nBest regards,\nThe Team"

  AdminMailer.reply_to_contact_message(message, reply_text, 'admin@yourstore.com').deliver_now
  puts "✓ Test email sent successfully!"
  puts "Check MailCatcher at http://localhost:1080 to view the email"
else
  puts "✗ No contact message found"
end
