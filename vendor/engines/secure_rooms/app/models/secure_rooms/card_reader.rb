module SecureRooms

  class CardReader < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id

    delegate :facility, to: :secure_room

  end

end
