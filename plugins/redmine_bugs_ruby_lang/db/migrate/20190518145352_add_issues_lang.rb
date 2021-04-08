class AddIssuesLang < ActiveRecord::Migration[5.2]
  def up
    add_column :issues, :lang, :string, :limit => 8, :default => "en"
  end

  def down
    remove_column :issues, :lang
  end
end
