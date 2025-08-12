# Create shipping methods
shipping_methods = [
  {
    name: 'Standard Shipping',
    description: 'Delivery in 5-7 business days',
    carrier: 'USPS',
    base_cost: 9.99,
    min_delivery_days: 5,
    max_delivery_days: 7,
    sort_order: 1,
    active: true
  },
  {
    name: 'Express Shipping',
    description: 'Delivery in 2-3 business days',
    carrier: 'UPS',
    base_cost: 19.99,
    min_delivery_days: 2,
    max_delivery_days: 3,
    sort_order: 2,
    active: true
  },
  {
    name: 'Next Day Delivery',
    description: 'Delivery by next business day',
    carrier: 'FedEx',
    base_cost: 29.99,
    min_delivery_days: 1,
    max_delivery_days: 1,
    sort_order: 3,
    active: true
  },
  {
    name: 'Free Shipping',
    description: 'Free delivery in 7-10 business days (orders over $50)',
    carrier: 'USPS',
    base_cost: 0.00,
    min_delivery_days: 7,
    max_delivery_days: 10,
    free_shipping_threshold: 50.00,
    sort_order: 4,
    active: true
  }
]

shipping_methods.each do |attrs|
  ShippingMethod.find_or_create_by!(name: attrs[:name]) do |method|
    method.assign_attributes(attrs)
  end
end

puts "Created #{ShippingMethod.count} shipping methods"
