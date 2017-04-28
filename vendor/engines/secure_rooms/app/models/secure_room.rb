class SecureRoom < Product

  include Products::ScheduleRuleSupport

  has_many :card_readers, foreign_key: :product_id, class_name: SecureRooms::CardReader
  has_many :events, foreign_key: :product_id, class_name: SecureRooms::Event
  has_many :occupancies, foreign_key: :product_id, class_name: SecureRooms::Occupancy

  before_validation :set_secure_room_defaults, on: :create

  def time_data_for(order_detail)
    order_detail.occupancy
  end

  private

  def set_secure_room_defaults
    self.requires_approval = true
    self.is_hidden = true
  end

end
