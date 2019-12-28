class CreateMailingListMessages < ActiveRecord::Migration[5.2]
  def self.up
    # create_table :mailing_list_messages do |t|
    #   t.string :message_id
    #   t.string :in_reply_to
    #   t.string :archive_url
    #   t.text :references
    #   t.integer :mail_number

    #   t.references :issue
    #   t.references :journal
    #   t.references :mailing_list, null: false
    # end

    # add_index :mailing_list_messages, :message_id
    # add_index :mailing_list_messages, :issue_id
    # add_index :mailing_list_messages, :journal_id
    # add_index :mailing_list_messages, [:issue_id, :journal_id]
    # add_index :mailing_list_messages, [:mailing_list_id, :message_id]
    # add_index :mailing_list_messages, [:mailing_list_id, :mail_number]
  end

  def self.down
    drop_table :mailing_list_messages
  end
end
