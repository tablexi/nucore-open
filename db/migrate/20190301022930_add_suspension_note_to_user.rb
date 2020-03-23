# frozen_string_literal: true

class AddSuspensionNoteToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :suspension_note, :string, after: :suspended_at
  end
end
