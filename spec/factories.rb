FactoryBot.define do
  factory :coupon do
    sequence(:code) { |n| "SAVE#{n}" }
    discount_type { "fixed" }
    discount_value { 25.00 }
    valid_from { 1.week.ago }
    valid_until { 1.week.from_now }
    min_order_amount { 0.00 }
    max_discount_amount { nil }
    usage_limit { 100 }
    used_count { 0 }
    active { true }

    trait :percentage do
      discount_type { "percentage" }
      discount_value { 20.0 }
    end

    trait :expired do
      valid_until { 1.day.ago }
    end

    trait :inactive do
      active { false }
    end

    trait :high_minimum do
      min_order_amount { 500.00 }
    end
  end

  factory :review do
    association :user
    association :product
    rating { rand(1..5) }
    title { Faker::Lorem.sentence(word_count: 3) }
    content { Faker::Lorem.paragraph(sentence_count: 3) }
  end

  factory :wishlist do
    association :user
    association :product
  end

  factory :contact_message do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    subject { Faker::Lorem.sentence(word_count: 6) }
    message { Faker::Lorem.paragraph(sentence_count: 5) }
    status { :pending }

    trait :read do
      status { :read }
      read_at { Time.current }
    end

    trait :replied do
      status { :replied }
      read_at { 1.hour.ago }
    end

    trait :archived do
      status { :archived }
      read_at { 2.hours.ago }
    end
  end

  factory :newsletter do
    email { "MyString" }
    subscribed_at { "2025-08-12 13:13:50" }
  end

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
    slug { name&.parameterize }
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

    trait :with_coupon do
      association :coupon
      after(:create) do |checkout|
        checkout.update!(
          coupon_code: checkout.coupon.code,
          discount_amount: checkout.coupon.discount_value
        )
      end
    end
  end
end
