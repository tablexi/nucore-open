FactoryGirl.define do
  factory :occupancy, class: SecureRooms::Occupancy do
    secure_room
    user

    trait :active do
      with_entry
    end

    trait :orphan do
      with_entry
      orphaned_at { Time.current }
    end

    trait :complete do
      with_entry
      with_exit
    end

    trait :with_entry do
      association :entry_event, factory: :event
      entry_at { entry_event.occurred_at }
    end

    trait :with_exit do
      association :exit_event, factory: :event
      exit_at { exit_event.occurred_at }
    end
  end
end
