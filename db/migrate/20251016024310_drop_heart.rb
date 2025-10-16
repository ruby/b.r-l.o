class DropHeart < ActiveRecord::Migration[7.2]
  def change
    drop_table :hearts if table_exists?(:hearts)
  end
end
