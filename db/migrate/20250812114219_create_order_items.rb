class CreateOrderItems < ActiveRecord::Migration[8.0]
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

      # Pricing information
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0

      # Tax information
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :tax_rate, precision: 5, scale: 4, default: 0
      t.boolean :taxable, default: true

      t.timestamps
    end

    add_index :order_items, [:order_id, :product_id]
    add_index :order_items, :product_sku
  end
end
