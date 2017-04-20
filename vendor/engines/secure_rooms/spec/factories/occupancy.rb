FactoryGirl.define do
  factory :occupancy, class: SecureRooms::Occupancy do
    secure_room
    user

    trait :active do
      association :entry_event, factory: :event
      entry_at { entry_event.occurred_at }
    end

    trait :orphan do
      association :entry_event, factory: :event
      entry_at { entry_event.occurred_at }
      orphaned_at { Time.current }
    end

    trait :complete do
      association :entry_event, factory: :event
      entry_at { entry_event.occurred_at }
      association :exit_event, factory: :event
      exit_at { exit_event.occurred_at }
    end
  end
end
