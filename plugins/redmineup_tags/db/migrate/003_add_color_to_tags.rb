class AddColorToTags < ActiveRecord::Migration[8.1]
  # The tags table on this instance was created by an old plugin version
  # without the color column. 002_create_tags.rb is guarded by
  # table_exists? and never adds it, so redmineup_tags 2.1.2 fails with
  # PG::UndefinedColumn. add_tags_column is a no-op when the column
  # already exists (fresh installs).
  def self.up
    ActiveRecord::Base.add_tags_column(:tags, name: :color, type: :integer, default: nil)
  end

  def self.down
  end
end
