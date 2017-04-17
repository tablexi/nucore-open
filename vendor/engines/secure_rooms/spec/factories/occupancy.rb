FactoryGirl.define do
  factory :occupancy, class: SecureRooms::Occupancy do
    secure_room
    user
  end
end
