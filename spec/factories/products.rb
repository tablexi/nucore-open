FactoryGirl.define do
  factory :product do
    description "Lorem ipsum..."
    account 71_234
    requires_approval false
    is_archived false
    is_hidden false
    initial_order_status_id { FactoryGirl.create(:order_status, name: "New").id }

    factory :instrument, class: Instrument do
      transient do
        no_relay false
      end

      sequence(:name) { |n| "Instrument #{n}" }
      sequence(:url_name) { |n| "instrument#{n}" }
      min_reserve_mins 60
      max_reserve_mins 120
      reserve_interval 1

      after(:create) do |inst, evaluator|
        inst.relay = FactoryGirl.create(:relay_dummy, instrument: inst) unless evaluator.no_relay
      end
    end

    factory :item, class: Item do
      sequence(:name) { |n| "Item #{n}" }
      sequence(:url_name) { |n| "item_url_#{n}" }
    end

    factory :service, class: Service do
      sequence(:name) { |n| "Service #{n}" }
      sequence(:url_name) { |n| "service#{n}" }
    end

    factory :bundle, class: Bundle do
      account nil # bundles don't have accounts
      sequence(:name) { |n| "Bundle #{n}" }
      sequence(:url_name) { |n| "bundle-#{n}" }
    end
  end

  factory :setup_product, class: Product do
    facility factory: :setup_facility

    sequence(:name) { |n| "Product #{n}" }
    sequence(:url_name) { |n| "product-#{n}" }
    description "Product description"
    account 71_234
    requires_approval false
    is_archived false
    is_hidden false
    initial_order_status { FactoryGirl.create(:order_status, name: "New") }
    min_reserve_mins 60
    max_reserve_mins 120

    after(:build) do |product|
      product.facility_account ||= product.facility.facility_accounts.first
    end

    after(:create) do |product|
      FactoryGirl.create(:price_group_product,
                         product: product,
                         price_group: product.facility.price_groups.last)
    end

    factory :setup_service, class: Service do
    end

    factory :setup_item, class: Item do
      after(:create) do |product|
        product.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, price_group: product.facility.price_groups.last))
      end
    end

    trait :with_facility_account do
      after(:build) do |product|
        product.facility_account =
          product.facility.facility_accounts.create(attributes_for(:facility_account))
      end
    end

    trait :with_order_form do
      after(:create) do |product|
        create(:stored_file, :template, product: product)
      end
    end
  end

  factory :setup_instrument, class: Instrument, parent: :setup_product do
    reserve_interval 1

    schedule { create :schedule, facility: facility }

    after(:create) do |product|
      create :schedule_rule, instrument: product
      create :instrument_price_policy, price_group: product.facility.price_groups.last, usage_rate: 1, product: product
      product.reload
    end

    trait :always_available do
      after(:create) do |product|
        product.schedule_rules.destroy_all
        create(:all_day_schedule_rule, instrument: product)
        product.reload
      end
    end
  end

  factory :instrument_requiring_approval, parent: :setup_instrument do
    requires_approval { true }
  end

end
