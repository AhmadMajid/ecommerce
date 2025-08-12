FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    quantity { 1 }
    price { 10.00 }
  end
end
