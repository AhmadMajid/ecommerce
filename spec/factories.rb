FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { '+1234567890' }  # Use a valid phone format
    role { :customer }
    active { true }
    confirmed_at { Time.current }
    date_of_birth { 25.years.ago.to_date }  # Add valid birth date
  end

  factory :admin_user, parent: :user do
    role { :admin }
  end

  factory :category do
    name { Faker::Commerce.department }
    description { Faker::Lorem.paragraph }
    slug { name.parameterize }
    active { true }
    position { Faker::Number.between(from: 1, to: 100) }
  end

  factory :product do
    association :category
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    short_description { Faker::Lorem.sentence }
    sku { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    slug { name.parameterize }
    price { Faker::Commerce.price(range: 10..100) }
    weight { Faker::Number.decimal(l_digits: 2, r_digits: 3) }
    inventory_quantity { 100 }  # Ensure sufficient inventory for tests
    track_inventory { true }
    allow_backorders { false }
    active { true }
    published_at { Time.current }
  end

  factory :cart do
    association :user, factory: :user
    session_id { SecureRandom.hex(16) }
    status { :active }
    expires_at { 30.days.from_now }
  end

  factory :cart_item do
    association :cart
    association :product
    quantity { Faker::Number.between(from: 1, to: 5) }
    price { product.price }
    product_name { product.name }
  end

  factory :shipping_method do
    name { ['Standard Shipping', 'Express Shipping', 'Overnight'].sample }
    description { Faker::Lorem.sentence }
    carrier { ['UPS', 'FedEx', 'USPS'].sample }
    base_cost { Faker::Commerce.price(range: 5..25) }
    cost_per_kg { Faker::Commerce.price(range: 1..5) }
    min_delivery_days { Faker::Number.between(from: 1, to: 3) }
    max_delivery_days { Faker::Number.between(from: 3, to: 7) }
    active { true }
    sort_order { Faker::Number.between(from: 1, to: 10) }
  end

  factory :address do
    association :user
    address_type { 'shipping' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    company { Faker::Company.name }
    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state_province { Faker::Address.state_abbr }
    postal_code { Faker::Address.zip_code }
    country { 'US' }
    phone { '+1234567890' }  # Use valid phone format
    default_address { false }
    active { true }
  end

  factory :checkout do
    association :user
    association :cart
    session_id { SecureRandom.hex(16) }
    status { 'started' }
    expires_at { 2.hours.from_now }

    trait :with_shipping_info do
      status { 'shipping_info' }
      shipping_address do
        {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'address_line_1' => '123 Main St',
          'city' => 'Anytown',
          'state_province' => 'CA',
          'postal_code' => '12345',
          'country' => 'US'
        }.to_json
      end
      association :shipping_method
    end

    trait :with_payment_info do
      with_shipping_info
      status { 'payment_info' }
      payment_method { 'credit_card' }
      billing_address do
        {
          'first_name' => 'John',
          'last_name' => 'Doe',
          'address_line_1' => '123 Main St',
          'city' => 'Anytown',
          'state_province' => 'CA',
          'postal_code' => '12345',
          'country' => 'US'
        }.to_json
      end
    end

    trait :ready_for_review do
      with_payment_info
      status { 'review' }
    end

    trait :completed do
      ready_for_review
      status { 'completed' }
      completed_at { Time.current }
    end

    trait :expired do
      after(:create) do |checkout|
        checkout.update_column(:expires_at, 1.hour.ago)
      end
    end
  end
end
