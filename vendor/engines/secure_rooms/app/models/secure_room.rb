class SecureRoom < Product

  has_many :card_readers, class_name: SecureRooms::CardReader

end
