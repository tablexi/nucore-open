FactoryBot.define do
  factory :facility_account do
    facility
    revenue_account { Settings.accounts.revenue_account_default }
    sequence(:account_number) do |n|
      # This sequence was often running into blacklist problems
      # s = "1#{n%10}#{rand(10)}-7777777" # fund3-dept7
      "134-7#{'%06d' % n}"
    end

    is_active { true }
    created_by { 1 }

    after(:build) do |facility_account|
      define_open_account(facility_account.revenue_account, facility_account.account_number)
    end
  end
end
