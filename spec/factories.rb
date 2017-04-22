require File.expand_path("factories_env", File.dirname(__FILE__))

FactoryGirl.define do
  factory :instrument_status do
    is_on true
  end

  factory :product_access_group do
    sequence(:name) { |n| "Level #{n}" }
  end

  factory :statement_row do
    amount 5
  end

  factory :response_set do
    sequence(:access_code) { |n| "#{n}#{n}#{n}" }
  end

end
