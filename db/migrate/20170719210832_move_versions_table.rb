class MoveVersionsTable < ActiveRecord::Migration
  def change
    rename_table :versions, :vestal_versions
  end
end
