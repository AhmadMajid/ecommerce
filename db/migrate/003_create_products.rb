class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.text :short_description
      t.string :sku, null: false
      t.string :slug, null: false

      # Pricing
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2

      # Physical attributes
      t.decimal :weight, precision: 8, scale: 3
      t.decimal :length, precision: 8, scale: 3
      t.decimal :width, precision: 8, scale: 3
      t.decimal :height, precision: 8, scale: 3

      # Inventory
      t.integer :inventory_quantity, default: 0
      t.boolean :track_inventory, null: false, default: true
      t.boolean :allow_backorders, null: false, default: false
      t.integer :low_stock_threshold, default: 5

      # Status and visibility
      t.boolean :active, null: false, default: true
      t.boolean :featured, null: false, default: false
      t.datetime :published_at

      # SEO
      t.string :meta_title
      t.text :meta_description
      t.text :meta_keywords

      # Category association
      t.references :category, foreign_key: true, null: false

      # Tax and shipping
      t.boolean :taxable, null: false, default: true
      t.boolean :requires_shipping, null: false, default: true

      t.timestamps null: false
    end

    add_index :products, :sku, unique: true
    add_index :products, :slug, unique: true
    add_index :products, :active
    add_index :products, :featured
    add_index :products, :published_at
    add_index :products, [:active, :featured]
    add_index :products, [:category_id, :active]
    add_index :products, [:active, :published_at]
    add_index :products, :inventory_quantity
    add_index :products, [:track_inventory, :inventory_quantity]
  end
end
