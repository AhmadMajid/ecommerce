FactoryBot.define do
  factory :order do
    association :user
    sequence(:order_number) { |n| "ORD-#{n.to_s.rjust(6, '0')}" }
    email { user.email }
    status { 'pending' }
    payment_status { 'payment_pending' }
    fulfillment_status { 'unfulfilled' }
    currency { 'USD' }
    total { 100.00 }
    subtotal { 80.00 }
    tax_amount { 10.00 }
    shipping_amount { 10.00 }
    discount_amount { 0.00 }
  end
end
