FactoryGirl.define do
  factory :schedule_rule do
    discount_percent 0.00
    start_hour 9
    start_min 00
    end_hour 17
    end_min 00
    duration_mins 60
    on_sun true
    on_mon true
    on_tue true
    on_wed true
    on_thu true
    on_fri true
    on_sat true

    factory :weekend_schedule_rule do
      on_sun true
      on_mon false
      on_tue false
      on_wed false
      on_thu false
      on_fri false
      on_sat true
    end

    factory :all_day_schedule_rule do
      start_hour 0
      end_hour 24
    end
  end
end