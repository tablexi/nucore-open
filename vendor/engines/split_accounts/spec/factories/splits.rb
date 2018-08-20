FactoryBot.define do
  factory :split, class: SplitAccounts::Split, aliases: ["split_accounts/split"] do
    association :parent_split_account, factory: :split_account
    association :subaccount, factory: :setup_account
    percent { 100 }
    apply_remainder { true }
  end
end
