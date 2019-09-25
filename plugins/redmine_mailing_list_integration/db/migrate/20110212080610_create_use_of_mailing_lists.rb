class CreateUseOfMailingLists < ActiveRecord::Migration[5.2]
  def self.up
    create_table :uses_of_mailing_list do |t|
      t.string :receptor_name, null: false
      t.references :mailing_list, null: false
      t.references :project, null: false
      t.timestamps
    end

    add_index :uses_of_mailing_list, [:mailing_list_id, :project_id]
  end

  def self.down
    drop_table :use_of_mailing_lists
  end
end
