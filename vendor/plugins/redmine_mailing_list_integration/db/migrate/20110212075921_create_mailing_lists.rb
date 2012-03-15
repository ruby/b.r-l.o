class CreateMailingLists < ActiveRecord::Migration
  def self.up
    create_table :mailing_lists do |t|
      t.column :identifier, :string, :null => false, :unique => true
      t.column :address, :string, :null => false
      t.column :driver_name, :string, :null => false
      t.column :driver_data, :text
      t.column :description, :text
    end
  end

  def self.down
    drop_table :mailing_lists
  end
end
