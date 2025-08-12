class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :email, null: false
      t.decimal :total, precision: 10, scale: 2, null: false
      t.integer :status, default: 0
      t.integer :payment_status, default: 0
      t.integer :fulfillment_status, default: 0

      # Financial information
      t.string :currency, default: 'USD'
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :email
    add_index :orders, :status
    add_index :orders, :payment_status
  end
end
