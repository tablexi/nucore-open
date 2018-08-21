# frozen_string_literal: true

class RenameFilesTable < ActiveRecord::Migration

  def self.up
    rename_table :files, :file_uploads
  end

  def self.down
    rename_table :file_uploads, :files
  end

end
