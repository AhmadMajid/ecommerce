class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :subject, null: false
      t.text :message, null: false
      t.string :status, default: 'pending', null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :contact_messages, :status
    add_index :contact_messages, :created_at
    add_index :contact_messages, [:status, :created_at]
  end
end
