# frozen_string_literal: true

FactoryBot.define do
  factory :setup_kfs_facility, class: Facility, parent: :facility do
    after(:create) do |kfs_facility|
      FactoryBot.create(:kfs_facility_account, facility: kfs_facility)
      # user is_internal => false so that we can just use .last to access it
      FactoryBot.create(:price_group, facility: kfs_facility, is_internal: false)
    end
  end
end
