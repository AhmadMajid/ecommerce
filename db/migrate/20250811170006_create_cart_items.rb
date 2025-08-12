class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.integer :quantity, null: false, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false

      # Store product details at time of adding to cart
      t.string :product_name
      t.json :product_options # Store selected options

      # Gift message or customization
      t.text :custom_attributes

      t.timestamps
    end

    add_index :cart_items, [:cart_id, :product_id], unique: true
    add_index :cart_items, :created_at
  end
end
