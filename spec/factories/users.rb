FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "username#{n}" }
    first_name "User"
    password 'password'
    password_confirmation 'password'
    sequence(:last_name) { |n| "#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end

  trait :account_manager do
    after(:create) do |user, _|
      UserRole.grant(user, UserRole::ACCOUNT_MANAGER)
    end
  end

  trait :administrator do
    after(:create) do |user, _|
      UserRole.grant(user, UserRole::ADMINISTRATOR)
    end
  end

  trait :billing_administrator do
    after(:create) do |user, _|
      UserRole.grant(user, UserRole::BILLING_ADMINISTRATOR)
    end
  end

  trait :business_administrator do
    transient do
      account nil
      administrator nil
    end

    after(:create) do |user, evaluator|
      AccountUser.grant(
        user,
        AccountUser::ACCOUNT_ADMINISTRATOR,
        evaluator.account,
        evaluator.administrator,
      )
    end
  end

  trait :facility_administrator do
    transient { facility nil }

    after(:create) do |user, evaluator|
      UserRole.grant(user, UserRole::FACILITY_ADMINISTRATOR, evaluator.facility)
    end
  end

  trait :facility_director do
    transient { facility nil }

    after(:create) do |user, evaluator|
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, evaluator.facility)
    end
  end

  trait :purchaser do
    transient do
      account nil
      administrator nil
    end

    after(:create) do |user, evaluator|
      AccountUser.grant(
        user,
        AccountUser::ACCOUNT_PURCHASER,
        evaluator.account,
        evaluator.administrator,
      )
    end
  end

  trait :senior_staff do
    transient { facility nil }

    after(:create) do |user, evaluator|
      UserRole.grant(user, UserRole::FACILITY_SENIOR_STAFF, evaluator.facility)
    end
  end

  trait :staff do
    transient { facility nil }

    after(:create) do |user, evaluator|
      UserRole.grant(user, UserRole::FACILITY_STAFF, evaluator.facility)
    end
  end
end
