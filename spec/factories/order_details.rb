FactoryGirl.define do
  factory :order_detail do
    quantity 1
    created_by 0

    trait :completed do
      state "complete"
    end

    trait :canceled do
      state "canceled"
    end

    trait :canceled_with_cost do
      state "complete"
      canceled_at { 30.minutes.ago }
      actual_cost 5
    end
  end


end
