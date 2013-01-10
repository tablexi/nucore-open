FactoryGirl.define do
  factory :credit_card_account do
    sequence(:account_number) { |n| "5276-4400-6542-1319" }
    description 'credit card account description'
    name_on_card 'Person'
    expiration_month Time.zone.now.month
    expiration_year((Time.zone.now + 1.year).year)
    expires_at Time.zone.now + 1.month
    created_by 0
    sequence(:affiliate) { |n| Affiliate.find_or_create_by_name("cc_affiliate#{n}") }
  end

  factory :purchase_order_account do
    sequence(:account_number) { |n| "#{n}" }
    description 'purchase order account description'
    expires_at Time.zone.now + 1.month
    sequence(:affiliate) { |n| Affiliate.find_or_create_by_name("po_affiliate#{n}") }
    created_by 0
  end
end
