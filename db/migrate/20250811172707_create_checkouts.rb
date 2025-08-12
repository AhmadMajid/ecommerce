class CreateCheckouts < ActiveRecord::Migration[8.0]
  def change
    create_table :checkouts do |t|
      t.references :user, null: true, foreign_key: true
      t.references :cart, null: false, foreign_key: true
      t.json :shipping_address
      t.json :billing_address
      t.references :shipping_method, null: true, foreign_key: true
      t.string :payment_method
      t.string :status, default: 'started', null: false
      t.string :session_id, null: false
      t.decimal :total_amount, precision: 10, scale: 2
      t.decimal :subtotal, precision: 10, scale: 2
      t.decimal :tax_amount, precision: 10, scale: 2
      t.decimal :shipping_amount, precision: 10, scale: 2
      t.decimal :discount_amount, precision: 10, scale: 2
      t.text :notes
      t.datetime :expires_at

      t.timestamps
    end

    add_index :checkouts, [:session_id, :status]
    add_index :checkouts, [:user_id, :status]
    add_index :checkouts, :expires_at
  end
end
