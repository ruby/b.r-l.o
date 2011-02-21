class CreateMailingListMessages < ActiveRecord::Migration
  def self.up
    create_table :mailing_list_messages do |t|
      t.string  :message_id
      t.string :in_reply_to
      t.text :references
      t.references :mailing_list, :null => false
      t.integer :mail_number
      t.string  :archive_url

      t.references :issue
      t.references :journal

      t.index :message_id
      t.index :issue_id
      t.index :journal_id
      t.index [:issue_id, :journal_id], :unique => true
      t.index [:mailing_list_id, :message_id], :unique => true
      t.index [:mailing_list_id, :mail_number], :unique => true
    end
  end

  def self.down
    drop_table :mailing_list_messages
  end
end
