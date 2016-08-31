FactoryGirl.define do
  factory :order_detail do
    quantity 1
    created_by 0

    trait :default_status do
      after(:create) do |order_detail|
        order_detail.set_default_status!
      end
    end
  end
end
