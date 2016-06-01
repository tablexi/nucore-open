FactoryGirl.define do
  factory :facility do
    sequence(:name, "AAAAAAAA") { |n| "Facility#{n}" }
    sequence(:email) { |n| "facility-#{n}@example.com" }
    sequence(:abbreviation) { |n| "FA#{n}" }
    short_description "Short Description"
    description "Facility Description"
    is_active true
    sequence(:url_name) { |n| "facility#{n}" }

    trait :with_order_notification do
      sequence(:order_notification_recipient) { |n| "orders#{n}@example.com" }
    end
  end

  factory :setup_facility, class: Facility, parent: :facility do
    after(:create) do |facility|
      facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      # user is_internal => false so that we can just use .last to access it
      FactoryGirl.create(:price_group, facility: facility, is_internal: false)
    end
  end
end
