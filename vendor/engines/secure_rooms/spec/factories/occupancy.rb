FactoryGirl.define do
  factory :occupancy, class: SecureRooms::Occupancy do
    secure_room
    user

    trait :active do
      entry_event { create :event }
      entry_at { 1.hour.ago }
    end

    trait :orphan do
      entry_event { create :event }
      entry_at { 2.hours.ago }
      orphaned_at { 1.hour.ago }
    end

    trait :complete do
      entry_event { create :event }
      entry_at { 2.hours.ago }
      exit_event { create :event }
      exit_at { 1.hour.ago }
    end
  end
end
