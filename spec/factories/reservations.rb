FactoryGirl.define do
  factory :reservation do
    reserve_start_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day }
    reserve_end_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day + 1.hour }
  end
end
