FactoryGirl.define do
  factory :order do
    account nil
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

    factory :purchased_order do
      after_create do |order|
        order.stub(:cart_valid?).and_return(true) #so we don't have to worry about defining price groups, etc
        order.validate_order!
        order.purchase!
      end
    end
  end
end
