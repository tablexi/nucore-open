module SecureRooms

  class CardReader < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id

  end

end
