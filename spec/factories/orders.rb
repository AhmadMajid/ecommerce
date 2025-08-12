FactoryBot.define do
  factory :order do
    association :user
    association :shipping_method
    email { user.email }
    status { 'pending' }
    total_amount { 100.00 }
    shipping_address { { 'street' => '123 Test St', 'city' => 'Test City', 'state' => 'TS', 'zip' => '12345' } }
    billing_address { { 'street' => '123 Test St', 'city' => 'Test City', 'state' => 'TS', 'zip' => '12345' } }
  end
end
