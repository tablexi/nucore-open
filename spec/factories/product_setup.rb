FactoryGirl.define do
  factory :setup_facility, :class => Facility, :parent => :facility do
    after_create do |facility|
      facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      # user is_internal => false so that we can just use .last to access it
      facility.price_groups.create(FactoryGirl.attributes_for(:price_group, :is_internal => false))
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
    schedule { Factory.create(:schedule, :facility => facility) }
    after_create do |product|
      product.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy, :price_group => product.facility.price_groups.last, :usage_rate => 1))
      product.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    end
  end

  factory :setup_account, :class => NufsAccount, :parent => :nufs_account do
    ignore do
      owner { FactoryGirl.create(:user) }
    end

    account_users_attributes { [Hash[:user => owner, :created_by => owner, :user_role => 'Owner']] }
  end

  # Must define product or facility
  factory :setup_order, :class => Order do
    ignore do
      product { nil }
    end
    facility { product.facility }
    association :account, :factory => :setup_account
    user { account.owner.user }
    created_by { user }

    after_create do |order, evaluator|
      FactoryGirl.create(:user_price_group_member, :user => evaluator.user, :price_group => evaluator.product.facility.price_groups.last)
      order.add(evaluator.product)
    end
  end

  factory :setup_reservation, :class => Reservation, :parent => :reservation do
    product { FactoryGirl.create(:setup_instrument) }
    
    order_detail { FactoryGirl.create(:setup_order, :product => product).order_details.first }
  end

  factory :validated_reservation, :parent => :setup_reservation do
    after_create do |reservation|
      reservation.order.validate_order!
    end
  end

  factory :purchased_reservation, :parent => :validated_reservation do
    after_create do |reservation|
      reservation.order.purchase!
    end
  end
end
