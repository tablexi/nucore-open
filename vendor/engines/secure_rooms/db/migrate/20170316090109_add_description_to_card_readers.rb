# frozen_string_literal: true

class AddDescriptionToCardReaders < ActiveRecord::Migration

  def change
    add_column :secure_rooms_card_readers, :description, :string
  end

end
