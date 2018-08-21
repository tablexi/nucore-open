# frozen_string_literal: true

class RenameFileUploads < ActiveRecord::Migration

  def self.up
    rename_table :file_uploads, :stored_files
  end

  def self.down
    rename_table :stored_files, :file_uploads
  end

end
