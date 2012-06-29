Factory.define :credit_card_account, :class => CreditCardAccount do |o|
  o.sequence(:account_number) { |n| "5276-4400-6542-1319" }
  o.description 'credit card account description'
  o.name_on_card 'Person'
  o.expiration_month((Time.zone.now + 1.month).month)
  o.expiration_year((Time.zone.now + 1.month).year)
  o.expires_at Time.zone.now + 1.month
  o.created_by 0
  o.sequence(:affiliate) { |n| Affiliate.find_or_create_by_name("cc_affiliate#{n}") }
end

Factory.define :purchase_order_account, :class => PurchaseOrderAccount do |o|
  o.sequence(:account_number) { |n| "#{n}" }
  o.description 'purchase order account description'
  o.expires_at Time.zone.now + 1.month
  o.sequence(:affiliate) { |n| Affiliate.find_or_create_by_name("po_affiliate#{n}") }
  o.created_by 0
end
