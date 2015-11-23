overridable_factory :nufs_account do
  sequence(:account_number) do |n|
    "9#{'%02d' % n}-7777777" # fund3-dept7
  end

  sequence(:description, 'aaaaaaaa') { |n| "nufs account #{n}" }
  expires_at { Time.zone.now + 1.month }
  created_by 0
end

FactoryGirl.modify do
  factory :nufs_account do
    trait :with_order do
      with_account_owner

      transient do
        product nil
      end

      account_users_attributes { [FactoryGirl.attributes_for(:account_user, user: owner)] }

      after(:create) do |account, evaluator|
        order = FactoryGirl.create(
          :order,
          user: evaluator.owner,
          created_by: evaluator.owner.id,
          facility: evaluator.product.facility,
        )

        FactoryGirl.create(
          :order_detail,
          product: evaluator.product,
          order: order,
          account: account,
        )
      end
    end
  end
end

FactoryGirl.define do
  factory :setup_account, :class => NufsAccount, :parent => :nufs_account do
    transient do
      owner { create(:user) }
    end

    account_users_attributes { account_users_attributes_hash(:user => owner) }

    after(:build) do |model|
      define_open_account '42345', model.account_number
    end
  end
end
