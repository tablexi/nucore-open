FactoryBot.define do
  factory :order do
    account nil
  end

  # Must define product or facility
  factory :setup_order, class: Order do
    transient do
      product { nil }
    end
    facility { product.facility }
    association :account, factory: :setup_account
    user { account.owner.user }
    created_by { account.owner.user.id }

    trait :purchased do
      ordered_at { 1.week.ago }
      state "purchased"
    end

    after(:create) do |order, evaluator|
      # build().save will allow an already existing relation without raising an error
      build(:account_price_group_member, account: order.account, price_group: evaluator.product.facility.price_groups.last).save
      build(:user_price_group_member, user: evaluator.user, price_group: evaluator.product.facility.price_groups.last).save
      order.add(evaluator.product)
    end

    factory :purchased_order do
      after(:create) do |order|
        allow(order).to receive(:cart_valid?).and_return(true) # so we don't have to worry about defining price groups, etc
        order.validate_order!
        order.purchase!
      end
    end

    factory :complete_order, parent: :purchased_order do
      after(:create) do |order|
        order.order_details.each(&:to_complete!)
      end
    end

    factory :merge_order do
      transient do
        merge_with_order { nil }
      end
      product { merge_with_order.order_details.first.product }
      account { merge_with_order.account }
      user { merge_with_order.user }
    end
  end
end
