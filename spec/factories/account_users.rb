FactoryGirl.define do
  factory :account_user do
    user_role 'Owner' # TODO: explicitly use the :owner trait
    created_by 0

    trait :inactive do
      deleted_at { 1.day.ago }
      deleted_by 0
    end

    trait :owner do
      user_role "Owner"
    end

    trait :purchaser do
      user_role "Purchaser"
    end
  end
end
