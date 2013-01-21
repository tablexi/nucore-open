FactoryGirl.define do
  factory :product do
    description 'Lorem ipsum...'
    account 51234
    requires_approval false
    is_archived false
    is_hidden false
    initial_order_status_id { |o| find_order_status('New').id }

    factory :instrument, :class => Instrument do
      ignore do
        no_relay false
      end    

      sequence(:name) { |n| "Instrument #{n}" }
      sequence(:url_name) { |n| "instrument#{n}"  }
      min_reserve_mins 60
      max_reserve_mins 120

      after_create do |inst, evaluator|
        inst.relay = FactoryGirl.create(:relay_dummy, :instrument => inst) unless evaluator.no_relay
      end
    end

    factory :item, :class => Item do
      sequence(:name) { |n| "Item #{n}" }
      sequence(:url_name) { |n| "item_url_#{n}" }
    end

    factory :service, :class => Service do
      sequence(:name) { |n| "Service #{n}" }
      sequence(:url_name) { |n| "service#{n}" }
    end

    factory :bundle, :class => Bundle do
      sequence(:name) {|n| "Bundle #{n}" }
      sequence(:url_name) {|n| "bundle-#{n}" }
    end
  end

  factory :setup_product, :class => Product do
    facility :factory => :setup_facility
    
    sequence(:name) { |n| "Product #{n}" }
    sequence(:url_name) { |n| "product-#{n}" }
    description "Product description"
    account 51234
    requires_approval false
    is_archived false
    is_hidden false
    initial_order_status { find_order_status('New') }
    min_reserve_mins 60
    max_reserve_mins 120 

    after_build do |product|
      product.facility_account = product.facility.facility_accounts.first
    end

    after_create do |product|
      FactoryGirl.create(:price_group_product, 
                           :product => product, 
                           :price_group => product.facility.price_groups.last)
    end
  end

  factory :setup_instrument, :class => Instrument, :parent => :setup_product do
    schedule { FactoryGirl.create(:schedule, :facility => facility) }
    after_create do |product|
      product.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy, :price_group => product.facility.price_groups.last, :usage_rate => 1))
      product.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    end
  end

  
end
