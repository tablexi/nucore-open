FactoryGirl.define do
  factory :card_reader, class: SecureRooms::CardReader do
    secure_room
    sequence(:card_reader_number) { |n| "card_reader_#{n}" }
    sequence(:control_device_number) { |n| "control_device_#{n}" }
  end
end
