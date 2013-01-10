FactoryGirl.define do
  factory :facility do
    sequence(:name) { |n| "Facility#{n}" }
    sequence(:email) { |n| "facility-#{n}@example.com" }
    sequence(:abbreviation) { |n| "FA#{n}" }
    short_description 'Short Description'
    description 'Facility Description'
    is_active true
    sequence(:url_name) { |n| "facility#{n}" }
  end
end
