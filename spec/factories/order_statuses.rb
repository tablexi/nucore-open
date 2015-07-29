FactoryGirl.define do
  factory :order_status do
    sequence(:name) { |n| "Status #{n}" }
  end
end
