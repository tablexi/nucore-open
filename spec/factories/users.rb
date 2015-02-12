FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "username#{n}" }
    first_name "User"
    password 'password'
    password_confirmation 'password'
    sequence(:last_name) { |n| "#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end

  trait :administrator do
    after(:create) do |user, _|
      UserRole.grant(user, UserRole::ADMINISTRATOR)
    end
  end

  trait :facility_director do
    transient { facility nil }

    after(:create) do |user, evaluator|
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, evaluator.facility)
    end
  end
end
