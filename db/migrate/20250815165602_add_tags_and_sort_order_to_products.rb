class AddTagsAndSortOrderToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :tags, :text
    add_column :products, :sort_order, :integer, default: 0
    add_index :products, :sort_order
  end
end
