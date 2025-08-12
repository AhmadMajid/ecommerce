class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address_type, null: false  # 'shipping', 'billing'
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :company
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :city, null: false
      t.string :state_province, null: false
      t.string :postal_code, null: false
      t.string :country, null: false, default: 'US'
      t.string :phone
      t.boolean :default_address, default: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :addresses, :user_id
    add_index :addresses, [:user_id, :address_type]
    add_index :addresses, [:user_id, :default_address]
    add_index :addresses, :active
  end
end
