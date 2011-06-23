[ 'factories', 'nucs_validator_helper' ].each do |nucs_file|
  require File.join(File.dirname(__FILE__), '..', 'vendor', 'plugins', 'nucs', 'spec', nucs_file)
end

include NucsValidatorHelper


Factory.define :facility, :class => Facility do |f|
  f.sequence(:name) { |n| "Facility#{n}" }
  f.sequence(:abbreviation) { |n| "FA#{n}" }
  f.short_description 'Short Description'
  f.description 'Facility Description'
  f.is_active true
  f.sequence(:url_name) { |n| "facility#{n}" }
end

Factory.define :facility_account, :class => FacilityAccount do |o|
  o.revenue_account 12345
  o.sequence(:account_number) do |n|
    s = "1#{n%10}#{rand(10)}-7777777" # fund3-dept7
    define_open_account(12345, s)
    s
  end

  o.is_active true
  o.created_by 1
end

Factory.define :user, :class => User do |o|
  o.sequence(:username) { |n| "username#{n}" }
  o.first_name "User"
  o.password 'password'
  o.sequence(:last_name) { |n| "#{n}" }
  o.sequence(:email) { |n| "user#{n}@example.com" }
end

Factory.define :order, :class => Order do |o|
  o.account nil
end

Factory.define :order_detail, :class => OrderDetail do |o|
  o.quantity 1
end

Factory.define :nufs_account, :class => NufsAccount do |o|
  o.sequence(:account_number) do |n| 
    s = "9#{n%10}#{rand(10)}-7777777" # fund3-dept7
    define_gl066(s)
    s
  end
  o.description 'nufs account description'
  o.expires_at Time.zone.now + 1.month
  o.created_by 0
end

Factory.define :credit_card_account, :class => CreditCardAccount do |o|
  o.sequence(:account_number) { |n| "5276-4400-6542-1319" }
  o.description 'credit card account description'
  o.name_on_card 'Person'
  o.expiration_month((Time.zone.now + 1.month).month)
  o.expiration_year((Time.zone.now + 1.month).year)
  o.expires_at Time.zone.now + 1.month
  o.created_by 0
end

Factory.define :purchase_order_account, :class => PurchaseOrderAccount do |o|
  o.sequence(:account_number) { |n| "#{n}" }
  o.description 'purchase order account description'
  o.expires_at Time.zone.now + 1.month
  o.created_by 0
end

Factory.define :account_user, :class => AccountUser do |o|
end

Factory.define :price_group, :class => PriceGroup do |o|
  o.sequence(:name) { |n| "Price Group #{n}" }
  o.display_order 999
  o.is_internal true
end

Factory.define :user_price_group_member, :class => UserPriceGroupMember do |o|
end

Factory.define :account_price_group_member, :class => AccountPriceGroupMember do |o|
end

Factory.define :instrument, :class => Instrument do |o|
  o.sequence(:name) { |n| "Instrument #{n}" }
  o.sequence(:url_name) { |n| "instrument#{n}"  }
  o.description 'Lorem ipsum...'
  o.account 51234
  o.requires_approval false
  o.is_archived false
  o.is_hidden false
  o.relay_type 'RelaySynaccessRevA'
  o.sequence(:relay_port) {|p| p }
  o.initial_order_status_id { |o| find_order_status('new') }
  o.min_reserve_mins 60
  o.max_reserve_mins 120
end

Factory.define :instrument_price_policy, :class => InstrumentPricePolicy do |o|
  o.unit_cost 1
  o.unit_subsidy 0
  o.reservation_rate 1
  o.reservation_subsidy 0
  o.reservation_mins 1
  o.minimum_cost 1
  o.usage_mins 1
  o.overage_mins 1
  o.start_date Time.zone.now.beginning_of_day
  o.expire_date Time.zone.now+1.month
end

Factory.define :item, :class => Item do |o|
  o.sequence(:name) { |n| "Item #{n}" }
  o.sequence(:url_name) { |n| "item_url_#{n}" }
  o.description       'Lorem ipsum...'
  o.account           51234
  o.requires_approval false
  o.is_archived       false
  o.is_hidden         false
  o.initial_order_status_id { |o| find_order_status('new') }
end

Factory.define :item_price_policy, :class => ItemPricePolicy do |o|
  o.unit_cost 1
  o.unit_subsidy 0
  o.start_date Date.today
  o.expire_date Time.zone.now+1.month
end

Factory.define :service, :class => Service do |o|
  o.sequence(:name) { |n| "Service #{n}" }
  o.sequence(:url_name) { |n| "service#{n}" }
  o.account 51234
  o.requires_approval false
  o.is_archived false
  o.is_hidden false
  o.initial_order_status_id { |o| find_order_status('new') }
end

Factory.define :bundle do |b|
  b.sequence(:name) {|n| "Bundle #{n}" }
  b.sequence(:url_name) {|n| "bundle-#{n}" }
  b.requires_approval false
  b.is_archived false
  b.is_hidden false
end

Factory.define :order_status, :class => OrderStatus do |o|
  o.sequence(:name) { |n| "Status #{n}" }
end

Factory.define :service_price_policy, :class => ServicePricePolicy do |o|
  o.unit_cost 1
  o.unit_subsidy 0
  o.start_date Date.today
  o.expire_date Time.zone.now+1.month
end

Factory.define :schedule_rule, :class => ScheduleRule do |o|
  o.discount_percent 0.00
  o.start_hour 9
  o.start_min 00
  o.end_hour 17
  o.end_min 00
  o.duration_mins 60
  o.on_sun true
  o.on_mon true
  o.on_tue true
  o.on_wed true
  o.on_thu true
  o.on_fri true
  o.on_sat true
end

Factory.define :payment_account_transaction do |pat|
  pat.description 'fake trans'
  pat.transaction_amount -12.34
  pat.finalized_at Time.zone.now
  pat.reference 'abc123xyz'
  pat.is_in_dispute false
end

Factory.define :statement do |s|
end

Factory.define :statement_row do |s|
  s.amount 5
end

Factory.define :reservation do |r|
  time=Time.parse('9:30') + 1.day
  r.reserve_start_at time
  r.reserve_end_at time + 1.hour
end

Factory.define :journal do |j|
  j.is_successful true
end

Factory.define :file_upload do |f|
  f.swf_uploaded_data ActionController::TestUploadedFile.new("#{Rails.root}/spec/files/flash_file.swf", 'application/x-shockwave-flash')
  f.name "#{Rails.root}/spec/files/flash_file.swf"
  f.file_type 'info'
end

Factory.define :response_set do |s|
  s.sequence(:access_code) { |n| "#{n}#{n}#{n}" }
end

Factory.define :price_group_product do |pgp|
  pgp.reservation_window 1
end