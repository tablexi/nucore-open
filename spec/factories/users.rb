FactoryGirl.define do
  factory :user do
    sequence(:username) { |n| "username#{n}" }
    first_name "User"
    password 'password'
    password_confirmation 'password'
    sequence(:last_name) { |n| "#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
