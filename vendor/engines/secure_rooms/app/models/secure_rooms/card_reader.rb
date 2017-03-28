module SecureRooms

  class CardReader < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id

    validates :card_reader_number, :control_device_number, presence: true
    validates :card_reader_number, uniqueness: true

  end

end
