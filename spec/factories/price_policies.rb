FactoryGirl.define do
  factory :instrument_price_policy do
    unit_cost 1
    unit_subsidy 0
    reservation_rate 1
    reservation_subsidy 0
    reservation_mins 1
    minimum_cost 1
    usage_mins 1
    overage_mins 1
    can_purchase true
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(Time.zone.now.beginning_of_day) }
  end

  factory :item_price_policy do
    can_purchase true
    unit_cost 1
    unit_subsidy 0
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(Date.today) }
  end

  factory :service_price_policy do
    can_purchase true
    unit_cost 1
    unit_subsidy 0
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(Date.today) }
  end
end
