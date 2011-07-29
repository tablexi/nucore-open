class ChangeVestalVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :reason_for_update, :string
    add_column :versions, :reverted_from, :integer
    add_column :versions, :commit_label, :string

    rename_column :versions, :data_changes, :modifications
    execute %Q[ ALTER TABLE versions RENAME COLUMN "NUMBER" TO "VERSION_NUMBER" ]

    add_index :versions, :commit_label
  end

  def self.down
    remove_index :versions, :commit_label
    execute %Q[ ALTER TABLE versions RENAME COLUMN "VERSION_NUMBER" TO "NUMBER" ]
    rename_column :versions, :modifications, :data_changes
    remove_columns :versions, :reason_for_update, :reverted_from, :commit_label
  end
end
