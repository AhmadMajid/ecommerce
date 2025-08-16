require_relative 'config/environment'
require 'factory_bot_rails'

puts "Testing checkout flow..."

# Set up the same way as the test
user = FactoryBot.create(:user)
cart = FactoryBot.create(:cart, user: user)
product = FactoryBot.create(:product)
cart_item = FactoryBot.create(:cart_item, cart: cart, product: product)
shipping_method = FactoryBot.create(:shipping_method)

checkout = FactoryBot.create(:checkout, :with_shipping_info, user: user, cart: cart)

puts "Created objects:"
puts "- User: #{user.email}"
puts "- Cart: #{cart.id} (items: #{cart.cart_items.count})"
puts "- Product: #{product.name}"
puts "- Cart item: #{cart_item.id} (qty: #{cart_item.quantity})"
puts "- Shipping method: #{shipping_method.id} - #{shipping_method.name}"
puts "- Checkout: #{checkout.id}"
puts "  - Status: #{checkout.status}"
puts "  - Shipping address: #{checkout.shipping_address.present?}"
puts "  - Shipping method ID: #{checkout.shipping_method_id}"
puts "  - Can proceed to payment?: #{checkout.can_proceed_to_payment?}"

# Debug the can_proceed_to_payment? method
puts "\nDebugging can_proceed_to_payment?:"
puts "- shipping_info_step_or_later?: #{checkout.shipping_info_step_or_later?}"
puts "- shipping_address.present?: #{checkout.shipping_address.present?}"
puts "- shipping_method_id.present?: #{checkout.shipping_method_id.present?}"

puts "\nCheckout object details:"
puts "- shipping_address: #{checkout.shipping_address}"
puts "- shipping_address_data: #{checkout.shipping_address_data}"
puts "- shipping_method: #{checkout.shipping_method&.name rescue 'ERROR LOADING'}"
puts "- shipping_method_id: #{checkout.shipping_method_id}"
