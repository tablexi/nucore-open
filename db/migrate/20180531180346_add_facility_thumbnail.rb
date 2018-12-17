# frozen_string_literal: true

class AddFacilityThumbnail < ActiveRecord::Migration[5.0]
  def change
    add_attachment :facilities, :thumbnail
  end
end
