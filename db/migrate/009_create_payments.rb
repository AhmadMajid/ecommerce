class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true

      # Payment identification
      t.string :payment_id, null: false # External payment processor ID
      t.string :payment_intent_id # Stripe payment intent ID
      t.string :transaction_id # Bank transaction reference

      # Payment details
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, default: 'USD'
      t.integer :status, default: 0 # pending, processing, succeeded, failed, cancelled, refunded
      t.integer :payment_method, default: 0 # credit_card, debit_card, paypal, apple_pay, google_pay, bank_transfer

      # Payment processor information
      t.string :gateway, null: false # stripe, paypal, square, etc.
      t.string :gateway_transaction_id
      t.text :gateway_response # Store full response for debugging

      # Card information (if applicable)
      t.string :card_brand # visa, mastercard, amex, etc.
      t.string :card_last_four
      t.string :card_exp_month
      t.string :card_exp_year
      t.string :card_fingerprint

      # Authorization and capture
      t.boolean :authorized, default: false
      t.boolean :captured, default: false
      t.datetime :authorized_at
      t.datetime :captured_at
      t.string :authorization_code

      # Refund information
      t.decimal :refunded_amount, precision: 10, scale: 2, default: 0
      t.datetime :refunded_at
      t.string :refund_reason
      t.string :refund_id # External refund ID

      # Failure information
      t.string :failure_code
      t.string :failure_message
      t.text :failure_details

      # Processing fees
      t.decimal :processing_fee, precision: 10, scale: 2
      t.decimal :net_amount, precision: 10, scale: 2

      # Risk assessment
      t.integer :risk_level, default: 0 # low, medium, high
      t.text :risk_details

      # Customer information
      t.string :customer_ip_address
      t.string :customer_user_agent

      # Billing address verification
      t.string :avs_result_code
      t.string :cvv_result_code

      # Metadata
      t.json :metadata # Additional data from payment processor

      t.timestamps
    end

    add_index :payments, :order_id
    add_index :payments, :payment_id, unique: true
    add_index :payments, :payment_intent_id
    add_index :payments, :transaction_id
    add_index :payments, :status
    add_index :payments, :gateway
    add_index :payments, [:order_id, :status]
    add_index :payments, [:gateway, :status]
    add_index :payments, :created_at
    add_index :payments, :captured_at
    add_index :payments, :refunded_at
    add_index :payments, :amount
    add_index :payments, :card_fingerprint
  end
end
