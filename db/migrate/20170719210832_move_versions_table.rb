# frozen_string_literal: true

class MoveVersionsTable < ActiveRecord::Migration
  def change
    rename_table :versions, :vestal_versions
  end
end
