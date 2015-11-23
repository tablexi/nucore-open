FactoryGirl.define do
  factory :split, class: SplitAccounts::Split do
    association :parent_split_account, factory: :split_account
    subaccount { build(:setup_account) }
    percent 100
    extra_penny true
  end
end
