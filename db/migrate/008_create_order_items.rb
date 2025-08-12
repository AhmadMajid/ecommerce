class CreateOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :product_variant, null: true, foreign_key: true

      # Product information (snapshot at time of order)
      t.string :product_name, null: false
      t.string :product_sku, null: false
      t.string :variant_title
      t.string :variant_sku
      t.json :product_options # Store selected variant options

      # Pricing information
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0

      # Tax information
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :tax_rate, precision: 5, scale: 4, default: 0
      t.boolean :taxable, default: true

      # Physical attributes
      t.decimal :weight, precision: 8, scale: 2
      t.string :weight_unit, default: 'kg'

      # Fulfillment
      t.integer :fulfillment_status, default: 0 # unfulfilled, fulfilled, returned
      t.integer :quantity_fulfilled, default: 0
      t.integer :quantity_returned, default: 0
      t.datetime :fulfilled_at

      # Shipping
      t.boolean :requires_shipping, default: true
      t.string :tracking_number

      # Customization or gift message
      t.text :custom_attributes
      t.text :gift_message

      # Return/Exchange information
      t.boolean :returnable, default: true
      t.datetime :return_deadline

      t.timestamps
    end

    add_index :order_items, :order_id
    add_index :order_items, :product_id
    add_index :order_items, :product_variant_id
    add_index :order_items, [:order_id, :product_id]
    add_index :order_items, :fulfillment_status
    add_index :order_items, :tracking_number
    add_index :order_items, :product_sku
    add_index :order_items, :variant_sku
  end
end
