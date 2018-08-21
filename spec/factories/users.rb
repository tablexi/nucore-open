# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "username#{n}" }
    first_name { "User" }
    password { "password" }
    password_confirmation { "password" }
    sequence(:last_name, &:to_s)
    sequence(:email) { |n| "user#{n}@example.com" }

    trait :suspended do
      suspended_at { 1.day.ago }
    end

    after(:create) do |user, _|
      user.create_default_price_group!
    end

    trait :external do
      username { email }
    end

    trait :account_manager do
      after(:create) do |user, _|
        UserRole.create!(user: user, role: UserRole::ACCOUNT_MANAGER)
      end
    end

    trait :administrator do
      after(:create) do |user, _|
        UserRole.create!(user: user, role: UserRole::ADMINISTRATOR)
      end
    end

    trait :billing_administrator do
      after(:create) do |user, _|
        UserRole.create!(user: user, role: UserRole::BILLING_ADMINISTRATOR)
      end
    end

    trait :business_administrator do
      transient do
        account { nil }
        administrator { nil }
      end

      after(:create) do |user, evaluator|
        AccountUser.grant(
          user,
          AccountUser::ACCOUNT_ADMINISTRATOR,
          evaluator.account,
          evaluator.administrator || user,
        )
      end
    end

    trait :facility_administrator do
      transient { facility { nil } }

      after(:create) do |user, evaluator|
        UserRole.create!(
          user: user,
          role: UserRole::FACILITY_ADMINISTRATOR,
          facility: evaluator.facility,
        )
      end
    end

    trait :facility_director do
      transient { facility { nil } }

      after(:create) do |user, evaluator|
        UserRole.create!(
          user: user,
          role: UserRole::FACILITY_DIRECTOR,
          facility: evaluator.facility,
        )
      end
    end

    trait :purchaser do
      transient do
        account { nil }
        administrator { nil }
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
      transient { facility { nil } }

      after(:create) do |user, evaluator|
        UserRole.create!(
          user: user,
          role: UserRole::FACILITY_SENIOR_STAFF,
          facility: evaluator.facility,
        )
      end
    end

    trait :staff do
      transient { facility { nil } }

      after(:create) do |user, evaluator|
        UserRole.create!(
          user: user,
          role: UserRole::FACILITY_STAFF,
          facility: evaluator.facility,
        )
      end
    end
  end
end
