class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true

      # Order identification
      t.string :order_number, null: false
      t.string :email, null: false

      # Order status
      t.integer :status, default: 0 # pending, confirmed, processing, shipped, delivered, cancelled, refunded
      t.integer :payment_status, default: 0 # pending, paid, partially_paid, refunded, partially_refunded
      t.integer :fulfillment_status, default: 0 # unfulfilled, partial, fulfilled

      # Customer information
      t.string :customer_first_name
      t.string :customer_last_name
      t.string :customer_phone

      # Billing address
      t.string :billing_first_name
      t.string :billing_last_name
      t.string :billing_company
      t.string :billing_address_line_1
      t.string :billing_address_line_2
      t.string :billing_city
      t.string :billing_state_province
      t.string :billing_postal_code
      t.string :billing_country
      t.string :billing_phone

      # Shipping address
      t.string :shipping_first_name
      t.string :shipping_last_name
      t.string :shipping_company
      t.string :shipping_address_line_1
      t.string :shipping_address_line_2
      t.string :shipping_city
      t.string :shipping_state_province
      t.string :shipping_postal_code
      t.string :shipping_country
      t.string :shipping_phone

      # Financial information
      t.string :currency, default: 'USD'
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :tip_amount, precision: 10, scale: 2, default: 0
      t.decimal :total, precision: 10, scale: 2, default: 0

      # Discounts and promotions
      t.string :coupon_code
      t.text :discount_details

      # Shipping information
      t.string :shipping_method
      t.decimal :shipping_rate, precision: 10, scale: 2
      t.string :tracking_number
      t.string :tracking_url
      t.datetime :shipped_at
      t.datetime :delivered_at

      # Notes and special instructions
      t.text :notes
      t.text :customer_notes
      t.text :admin_notes

      # Important dates
      t.datetime :processed_at
      t.datetime :cancelled_at
      t.string :cancel_reason

      # Tax information
      t.decimal :tax_rate, precision: 5, scale: 4
      t.boolean :tax_included, default: false
      t.text :tax_breakdown # JSON for detailed tax information

      # Refund information
      t.decimal :refunded_amount, precision: 10, scale: 2, default: 0
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :orders, :user_id
    add_index :orders, :order_number, unique: true
    add_index :orders, :email
    add_index :orders, :status
    add_index :orders, :payment_status
    add_index :orders, :fulfillment_status
    add_index :orders, [:user_id, :status]
    add_index :orders, [:status, :created_at]
    add_index :orders, :created_at
    add_index :orders, :processed_at
    add_index :orders, :shipped_at
    add_index :orders, :tracking_number
    add_index :orders, :total
    add_index :orders, :coupon_code
  end
end
