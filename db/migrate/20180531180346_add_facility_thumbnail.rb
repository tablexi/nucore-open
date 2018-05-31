class AddFacilityThumbnail < ActiveRecord::Migration[5.0]
  def change
    add_attachment :facilities, :thumbnail
  end
end
