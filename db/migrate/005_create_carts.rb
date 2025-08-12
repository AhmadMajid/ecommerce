class CreateCarts < ActiveRecord::Migration[7.0]
  def change
    create_table :carts do |t|
      t.references :user, null: true, foreign_key: true

      # For guest users
      t.string :session_id

      # Cart status
      t.integer :status, default: 0 # active, abandoned, converted
      t.datetime :expires_at

      # Currency
      t.string :currency, default: 'USD'

      # Totals (calculated fields)
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :total, precision: 10, scale: 2, default: 0

      # Applied discounts
      t.string :coupon_code

      # Notes
      t.text :notes

      t.timestamps
    end

    add_index :carts, :session_id
    add_index :carts, :status
    add_index :carts, :expires_at
    add_index :carts, [:user_id, :status]
    add_index :carts, [:session_id, :status]
    add_index :carts, :created_at
  end
end
