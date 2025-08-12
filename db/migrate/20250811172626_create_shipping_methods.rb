class CreateShippingMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :shipping_methods do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :carrier, null: false
      t.decimal :base_cost, precision: 10, scale: 2, null: false, default: 0
      t.decimal :cost_per_kg, precision: 10, scale: 2
      t.integer :min_delivery_days, null: false
      t.integer :max_delivery_days, null: false
      t.decimal :free_shipping_threshold, precision: 10, scale: 2
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :shipping_methods, :active
    add_index :shipping_methods, [:active, :sort_order]
  end
end
