class CreateUseOfMailingLists < ActiveRecord::Migration
  def self.up
    create_table :uses_of_mailing_list do |t|
      t.references :mailing_list, :null => false
      t.references :project, :null => false
      t.string :receptor_name, :null => false

      t.index [:mailing_list_id, :project_id]
    end
  end

  def self.down
    drop_table :use_of_mailing_lists
  end
end
