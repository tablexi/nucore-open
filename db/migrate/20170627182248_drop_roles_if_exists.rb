# frozen_string_literal: true

class DropRolesIfExists < ActiveRecord::Migration
  def up
    drop_table(:roles) if table_exists?(:roles)
  end

  def down
  end
end
