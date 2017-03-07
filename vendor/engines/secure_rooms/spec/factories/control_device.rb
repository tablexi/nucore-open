FactoryGirl.define do
  factory :control_device, class: SecureRooms::ControlDevice do
    secure_room
  end
end
