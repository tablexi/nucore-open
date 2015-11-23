FactoryGirl.define do
  factory :split do
    association :parent_split_account, factory: :split_account
    subaccount { build(:nufs_account, :with_owner) }
    percent 100
    extra_penny true
  end
end
