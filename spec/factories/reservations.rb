FactoryGirl.define do
  factory :reservation do
    reserve_start_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day }
    reserve_end_at { reserve_start_at + 1.hour }
  end

  factory :setup_reservation, :class => Reservation, :parent => :reservation do
    product :factory => :setup_instrument

    order_detail { FactoryGirl.create(:setup_order, :product => product).order_details.first }
  end

  factory :validated_reservation, :parent => :setup_reservation do
    after(:create) do |reservation|
      reservation.order.validate_order!
    end
  end

  factory :purchased_reservation, :parent => :validated_reservation do
    after(:create) do |reservation|
      reservation.order.purchase!
    end

    factory :completed_reservation do
      reserve_start_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") - 1.day }
      reserve_end_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") - 23.hours }
      reserved_by_admin true

      after(:create) do |reservation|
        reservation.order_detail.backdate_to_complete! reservation.reserve_end_at
      end
    end
  end
end
