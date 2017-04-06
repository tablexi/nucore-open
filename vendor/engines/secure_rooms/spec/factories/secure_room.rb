FactoryGirl.define do
  factory :secure_room, class: SecureRoom, parent: :setup_product do
    sequence(:name) { |n| "Room #{n}" }
    sequence(:url_name) { |n| "Room#{n}" }

    trait :with_schedule_rule do
      after(:create) do |room, _evaluator|
        room.schedule_rules.create(attributes_for(:schedule_rule))
      end
    end
  end
end
