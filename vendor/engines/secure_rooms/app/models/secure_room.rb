class SecureRoom < Product

  has_many :secure_rooms_control_devices
  has_many :card_readers, through: :control_devices

end
