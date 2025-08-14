class AddCouponFieldsToCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_column :checkouts, :coupon_code, :string
    add_reference :checkouts, :coupon, null: true, foreign_key: true
  end
end
