FactoryGirl.define do
  factory :secure_room, class: SecureRoom do
    sequence(:name) { |n| "user #{n}" }
    sequence(:url_name) { |n| "user-#{n}" }
    sequence(:account)
    sequence(:contact_email) { |n| "user#{n}@example.com" }
    facility
  end
end
