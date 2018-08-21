# frozen_string_literal: true

class AddCustomNoteFieldLabelToProduct < ActiveRecord::Migration

  def change
    add_column :products, :user_notes_label, :string
  end

end
