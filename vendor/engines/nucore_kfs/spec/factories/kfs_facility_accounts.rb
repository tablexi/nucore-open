# frozen_string_literal: true

FactoryBot.define do
  factory :kfs_facility_account, class: FacilityAccount do
    facility
    revenue_account { Settings.accounts.revenue_account_default }
    sequence(:account_number) do |n|
      "KFS-7777777-#{'%04d' % n}"
    end

    is_active { true }
    created_by { 1 }

    after(:build) do |kfs_facility_account|
      define_open_account(kfs_facility_account.revenue_account, kfs_facility_account.account_number)
    end
  end
end
