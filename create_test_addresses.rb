#!/usr/bin/env ruby

require_relative 'config/environment'

# Create a test user
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.first_name = 'Test'
  u.last_name = 'User'
end

# Create test shipping addresses
shipping1 = user.addresses.find_or_create_by(
  address_type: 'shipping',
  address_line_1: '123 Main St'
) do |addr|
  addr.first_name = 'John'
  addr.last_name = 'Doe'
  addr.address_line_2 = 'Apt 4B'
  addr.city = 'New York'
  addr.state_province = 'NY'
  addr.postal_code = '10001'
  addr.country = 'US'
  addr.phone = '+1234567890'
  addr.default_address = true
end

shipping2 = user.addresses.find_or_create_by(
  address_type: 'shipping',
  address_line_1: '456 Oak Avenue'
) do |addr|
  addr.first_name = 'John'
  addr.last_name = 'Doe'
  addr.company = 'ACME Corp'
  addr.city = 'Los Angeles'
  addr.state_province = 'CA'
  addr.postal_code = '90210'
  addr.country = 'US'
  addr.phone = '+1234567890'
end

billing1 = user.addresses.find_or_create_by(
  address_type: 'billing',
  address_line_1: '789 Pine St'
) do |addr|
  addr.first_name = 'John'
  addr.last_name = 'Doe'
  addr.city = 'Chicago'
  addr.state_province = 'IL'
  addr.postal_code = '60601'
  addr.country = 'US'
  addr.phone = '+1234567890'
  addr.default_address = true
end

puts "Created test addresses:"
puts "User: #{user.email}"
puts "Shipping addresses: #{user.addresses.shipping.count}"
puts "Billing addresses: #{user.addresses.billing.count}"
puts ""

# Test country name method
user.addresses.each do |addr|
  puts "#{addr.address_type.capitalize}: #{addr.country} -> #{addr.country_name}"
end
