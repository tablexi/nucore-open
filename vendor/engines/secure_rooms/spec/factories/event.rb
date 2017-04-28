FactoryGirl.define do
  factory :event, class: SecureRooms::Event do
    occurred_at { Time.current }
    card_reader
    user
    outcome :deny
  end
end
