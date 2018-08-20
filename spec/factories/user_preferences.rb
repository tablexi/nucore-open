FactoryBot.define do
  factory :user_preference do
    user
    name { "My Awesome Preference" }
    value { "Yay!" }

    trait :default_facility_home_page do
      name { "Facility Home Page" }
      value { "Dashboard" }
    end
  end
end
