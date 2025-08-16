#!/usr/bin/env ruby
# Test script to verify Stripe integration
# Run with: ruby stripe_test.rb

require_relative 'config/environment'

puts "🚀 Testing Stripe Integration..."
puts "=" * 50

# Check if keys are configured
publishable_key = Rails.application.config.stripe_publishable_key
secret_key = Stripe.api_key

if publishable_key&.start_with?('pk_test_')
  puts "✅ Publishable key found: #{publishable_key[0..20]}..."
else
  puts "❌ Publishable key missing or invalid"
  puts "   Expected: pk_test_..."
  puts "   Got: #{publishable_key}"
end

if secret_key&.start_with?('sk_test_')
  puts "✅ Secret key found: #{secret_key[0..20]}..."
else
  puts "❌ Secret key missing or invalid"
  puts "   Expected: sk_test_..."
  puts "   Got: #{secret_key}"
end

# Test API connection
if secret_key
  begin
    puts "\n🔌 Testing Stripe API connection..."
    account = Stripe::Account.retrieve
    puts "✅ Connected to Stripe! Account ID: #{account.id}"
    puts "   Business profile: #{account.business_profile&.name || 'Not set'}"
    puts "   Country: #{account.country}"
    puts "   Currency: #{account.default_currency&.upcase}"
  rescue => e
    puts "❌ Stripe API connection failed: #{e.message}"
  end
else
  puts "\n❌ Cannot test API connection - no secret key"
end

# Check webhook endpoint
begin
  puts "\n🔗 Checking webhook endpoint..."
  webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  if webhook_secret
    puts "✅ Webhook secret configured"
  else
    puts "⚠️  Webhook secret not configured (optional for development)"
  end
rescue => e
  puts "❌ Error checking webhook: #{e.message}"
end

# Check payment service
begin
  puts "\n💳 Testing PaymentService..."
  if defined?(PaymentService)
    puts "✅ PaymentService class found"
    # Test creating a payment intent (won't charge anything)
    service = PaymentService.new
    if service.respond_to?(:create_payment_intent)
      puts "✅ PaymentService#create_payment_intent method found"
    else
      puts "❌ PaymentService#create_payment_intent method missing"
    end
  else
    puts "❌ PaymentService class not found"
  end
rescue => e
  puts "❌ Error testing PaymentService: #{e.message}"
end

puts "\n" + "=" * 50
puts "🎯 Next Steps:"
puts "1. If keys are missing, add them to .env or Rails credentials"
puts "2. Start server: bin/rails server"
puts "3. Test checkout flow with test cards"
puts "4. Check STRIPE_SETUP_GUIDE.md for detailed instructions"
puts "=" * 50
