class CreateMailingLists < ActiveRecord::Migration
  def self.up
    create_table :mailing_lists do |t|
      t.string :identifier, null: false, unique: true
      t.string :address, null: false
      t.string :driver_name, null: false
      t.text :driver_data
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :mailing_lists
  end
end
