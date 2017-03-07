FactoryGirl.define do
  factory :card_reader, class: SecureRooms::CardReader do
    control_device
  end
end
