# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { "User" }
    sequence(:last_name) { |n| "Last#{n}" }
    sequence(:username) { |n| "username#{User.count + n}" }
    sequence(:email) { |n| "user#{User.count + n}@example.com" }

    trait :netid do
      password { nil }
      password_confirmation { nil }
    end

    trait :external do
      password { "P@ssw0rd!!" }
      password_confirmation { "P@ssw0rd!!" }
      username { email }
    end

    trait :suspended do
      suspended_at { 1.day.ago }
    end

    trait :expired do
      expired_at { 1.day.ago }
      expired_note { "Expired" }
    end

    after(:create) do |user, _|
      user.create_default_price_group!
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

    trait :global_billing_administrator do
      after(:create) do |user, _|
        UserRole.create!(user: user, role: UserRole::GLOBAL_BILLING_ADMINISTRATOR)
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
          by: evaluator.administrator || user,
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
          by: evaluator.administrator,
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

    trait :facility_billing_administrator do
      transient { facility { nil } }

      after(:create) do |user, evaluator|
        UserRole.create!(
          user: user,
          role: UserRole::FACILITY_BILLING_ADMINISTRATOR,
          facility: evaluator.facility,
        )
      end
    end
  end
end
