class CreateProductVariants < ActiveRecord::Migration[7.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true

      t.string :title, null: false
      t.string :sku, null: false
      t.string :barcode

      # Pricing (can override product pricing)
      t.decimal :price, precision: 10, scale: 2
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2

      # Inventory
      t.integer :inventory_quantity, default: 0
      t.boolean :track_inventory, default: true
      t.boolean :allow_backorder, default: false

      # Physical attributes
      t.decimal :weight, precision: 8, scale: 2
      t.string :weight_unit, default: 'kg'
      t.json :dimensions # {length: x, width: y, height: z, unit: 'cm'}

      # Variant options (size, color, material, etc.)
      t.string :option1_name
      t.string :option1_value
      t.string :option2_name
      t.string :option2_value
      t.string :option3_name
      t.string :option3_value

      # Status
      t.boolean :active, default: true
      t.integer :position, default: 0

      # Fulfillment
      t.boolean :requires_shipping, default: true
      t.boolean :taxable, default: true

      t.timestamps
    end

    add_index :product_variants, :sku, unique: true
    add_index :product_variants, :active
    add_index :product_variants, [:product_id, :active]
    add_index :product_variants, [:product_id, :position]
    add_index :product_variants, :inventory_quantity
    add_index :product_variants, :price
    add_index :product_variants, [:option1_name, :option1_value]
    add_index :product_variants, [:option2_name, :option2_value]
    add_index :product_variants, [:option3_name, :option3_value]
  end
end
