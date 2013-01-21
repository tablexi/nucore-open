overridable_factory :nufs_account do
  sequence(:account_number) do |n|
    "9#{'%02d' % n}-7777777" # fund3-dept7
  end

  description 'nufs account description'
  expires_at { Time.zone.now + 1.month }
  created_by 0
end

FactoryGirl.define do
  factory :setup_account, :class => NufsAccount, :parent => :nufs_account do
    ignore do
      owner { FactoryGirl.create(:user) }
    end

    account_users_attributes { [Hash[:user => owner, :created_by => owner, :user_role => 'Owner']] }

    after_build do |model|
      define_open_account '12345', model.account_number
    end
  end
end