FactoryGirl.define do
  factory :instrument_with_accessory, parent: :setup_instrument do
    transient do
      accessory { create :setup_item, facility: facility }
    end

    after(:create) do |instrument, evaluator|
      instrument.accessories << evaluator.accessory
    end

    trait :not_reservation_only do
      transient do
        no_relay false
      end

      min_reserve_mins 60
      max_reserve_mins 120
      reserve_interval 1

      after(:create) do |inst, evaluator|
        inst.relay = FactoryGirl.create(:relay_dummy, instrument: inst) unless evaluator.no_relay
      end
    end
  end

  factory :accessory, parent: :setup_item do
    transient do
      parent { create :setup_instrument, facility: facility }
      scaling_type "quantity"
    end

    after(:create) do |item, evaluator|
      evaluator.parent.product_accessories.create(accessory: item, scaling_type: evaluator.scaling_type)
    end
  end
end
