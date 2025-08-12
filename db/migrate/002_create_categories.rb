class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false
      t.string :meta_title
      t.text :meta_description
      t.references :parent, foreign_key: { to_table: :categories }, null: true
      t.integer :position, default: 0
      t.boolean :active, null: false, default: true
      t.boolean :featured, null: false, default: false

      t.timestamps null: false
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :active
    add_index :categories, :featured
    add_index :categories, [:active, :featured]
    add_index :categories, [:parent_id, :position]
  end
end
