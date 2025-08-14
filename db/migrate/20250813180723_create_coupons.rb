class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :discount_type, null: false # 'percentage' or 'fixed'
      t.decimal :discount_value, precision: 10, scale: 2, null: false
      t.datetime :valid_from
      t.datetime :valid_until
      t.decimal :min_order_amount, precision: 10, scale: 2, default: 0
      t.decimal :max_discount_amount, precision: 10, scale: 2
      t.integer :usage_limit
      t.integer :used_count, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :coupons, :code, unique: true
    add_index :coupons, :active
  end
end
