require File.expand_path("factories_env", File.dirname(__FILE__))

FactoryGirl.define do
  factory :instrument_status do
    is_on true
  end

  factory :product_access_group do
    sequence(:name) { |n| "Level #{n}" }
  end

  factory :payment_account_transaction do
    description "fake trans"
    transaction_amount -12.34
    finalized_at { Time.zone.now }
    reference "abc123xyz"
    is_in_dispute false
  end

  factory :statement_row do
    amount 5
  end

  factory :response_set do
    sequence(:access_code) { |n| "#{n}#{n}#{n}" }
  end

end
