class AddOrderIdToCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_reference :checkouts, :order, null: true, foreign_key: true
  end
end
