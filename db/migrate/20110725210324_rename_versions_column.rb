class RenameVersionsColumn < ActiveRecord::Migration
  def self.up
    execute %Q[ ALTER TABLE versions RENAME COLUMN "number" TO "NUMBER" ] if NUCore::Database.oracle?
  end

  def self.down
    execute %Q[ ALTER TABLE versions RENAME COLUMN "NUMBER" TO "number" ] if NUCore::Database.oracle?
  end
end
