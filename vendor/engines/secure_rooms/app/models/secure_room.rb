class SecureRoom < Product

  has_many :card_readers, class_name: SecureRooms::CardReader

  before_validation :set_secure_room_defaults, on: :create

  private

  def set_secure_room_defaults
    self.requires_approval = true
    self.is_hidden = true
  end

end
