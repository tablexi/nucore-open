module SecureRooms

  class ControlDevice < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id
    has_many :card_readers

  end

end
