# frozen_string_literal: true

FactoryBot.define do
  factory :account_user do
    user_role { "Owner" } # TODO: explicitly use the :owner trait
    created_by { 0 }

    trait :inactive do
      deleted_at { 1.day.ago }
      deleted_by { 0 }
    end

    trait :owner do
      user_role { AccountUser::ACCOUNT_OWNER }
    end

    trait :business_administrator do
      user_role { AccountUser::ACCOUNT_ADMINISTRATOR }
    end

    trait :purchaser do
      user_role { AccountUser::ACCOUNT_PURCHASER }
    end
  end
end
