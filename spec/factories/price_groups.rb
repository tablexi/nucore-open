FactoryGirl.define do
  factory :price_group do
    sequence(:name) { |n| "Price Group #{n}" }
    display_order 999
    is_internal true
  end

  factory :user_price_group_member do
  end

  factory :account_price_group_member do
  end

  factory :price_group_product do
    reservation_window 1
  end
end
