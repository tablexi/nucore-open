FactoryGirl.define do
  factory :statement do
    association :account, factory: :setup_account
    created_at { Time.zone.now }
    facility
  end
end
