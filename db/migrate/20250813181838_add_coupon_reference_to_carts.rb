class AddCouponReferenceToCarts < ActiveRecord::Migration[8.0]
  def change
    add_reference :carts, :coupon, null: true, foreign_key: true
  end
end
