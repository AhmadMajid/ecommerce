class CreateNewsletters < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletters do |t|
      t.string :email
      t.datetime :subscribed_at

      t.timestamps
    end
  end
end
