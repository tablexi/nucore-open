# frozen_string_literal: true

class AddAccountSuspendedAtField < ActiveRecord::Migration

  def self.up
    change_table :accounts do |t|
      t.datetime :suspended_at
    end
  end

  def self.down
    remove_column :accounts, :suspended_at
  end

end
