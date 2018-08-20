FactoryBot.define do
  factory :secure_room_price_policy do
    price_group
    usage_rate { 60 }
    usage_subsidy { 10 }
    minimum_cost { 30 }
    can_purchase { true }
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(Time.zone.now.beginning_of_day) }
  end
end
