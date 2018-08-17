FactoryBot.define do
  factory :schedule_rule do
    discount_percent { 0.00 }
    start_hour { 9 }
    start_min { 00 }
    end_hour { 17 }
    end_min { 00 }
    on_sun { true }
    on_mon { true }
    on_tue { true }
    on_wed { true }
    on_thu { true }
    on_fri { true }
    on_sat { true }

    trait :weekday do
      on_sun { false }
      on_sat { false }
    end

    trait :weekend do
      on_sun { true }
      on_mon { false }
      on_tue { false }
      on_wed { false }
      on_thu { false }
      on_fri { false }
      on_sat { true }
    end

    trait :all_day do
      start_hour { 0 }
      end_hour { 24 }
    end

    trait :evening do
      start_hour { 17 }
      end_hour { 24 }
    end

    factory :weekend_schedule_rule do
      weekend
    end

    factory :all_day_schedule_rule do
      all_day
    end
  end
end
