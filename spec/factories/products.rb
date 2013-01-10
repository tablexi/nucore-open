FactoryGirl.define do
  factory :product do
    description 'Lorem ipsum...'
    account 51234
    requires_approval false
    is_archived false
    is_hidden false
    initial_order_status_id { |o| find_order_status('New').id }

    factory :instrument, :class => Instrument do
      sequence(:name) { |n| "Instrument #{n}" }
      sequence(:url_name) { |n| "instrument#{n}"  }
      min_reserve_mins 60
      max_reserve_mins 120
      after_create do |inst|
        inst.relay = FactoryGirl.create(:relay_dummy, :instrument => inst)
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

  
end
