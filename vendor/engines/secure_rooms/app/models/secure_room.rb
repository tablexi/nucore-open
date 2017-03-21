class SecureRoom < Product

  include Products::ScheduleRuleSupport

  has_many :card_readers, foreign_key: :product_id, class_name: SecureRooms::CardReader

  before_validation :set_secure_room_defaults, on: :create

  private

  def set_secure_room_defaults
    self.requires_approval = true
    self.is_hidden = true
  end

end
