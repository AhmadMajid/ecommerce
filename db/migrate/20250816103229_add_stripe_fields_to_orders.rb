class AddStripeFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :stripe_payment_intent_id, :string
    add_column :orders, :stripe_customer_id, :string
  end
end
