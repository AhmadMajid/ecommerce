class CreatePayments < ActiveRecord::Migration[8.0]
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

      # Authorization and capture
      t.boolean :authorized, default: false
      t.boolean :captured, default: false
      t.datetime :authorized_at
      t.datetime :captured_at

      t.timestamps
    end

    add_index :payments, :payment_id, unique: true
    add_index :payments, :status
    add_index :payments, :gateway
  end
end
