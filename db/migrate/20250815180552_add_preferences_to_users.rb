class AddPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_notifications, :boolean, default: true, null: false
    add_column :users, :marketing_emails, :boolean, default: false, null: false
  end
end
