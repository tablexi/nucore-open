require File.expand_path('factories_env', File.dirname(__FILE__))


Factory.define_default :facility, :class => Facility do |f|
  f.sequence(:name) { |n| "Facility#{n}" }
  f.sequence(:abbreviation) { |n| "FA#{n}" }
  f.short_description 'Short Description'
  f.description 'Facility Description'
  f.is_active true
  f.sequence(:url_name) { |n| "facility#{n}" }
end

Factory.define_default :facility_account, :class => FacilityAccount do |o|
  o.revenue_account 12345
  o.sequence(:account_number) do |n|
    # This sequence was often running into blacklist problems
    # s = "1#{n%10}#{rand(10)}-7777777" # fund3-dept7
    s = "134-7#{"%06d" % n}"
    define_open_account(12345, s)
    s
  end

  o.is_active true
  o.created_by 1
end

Factory.define_default :user, :class => User do |o|
  o.sequence(:username) { |n| "username#{n}" }
  o.first_name "User"
  o.password 'password'
  o.password_confirmation 'password'
  o.sequence(:last_name) { |n| "#{n}" }
  o.sequence(:email) { |n| "user#{n}@example.com" }
end

Factory.define_default :order, :class => Order do |o|
  o.account nil
end

Factory.define_default :order_detail, :class => OrderDetail do |o|
  o.quantity 1
end

Factory.define_default :nufs_account, :class => NufsAccount do |o|
  o.sequence(:account_number) do |n|
    "9#{n%10}#{rand(10)}-7777777" # fund3-dept7
  end

  o.description 'nufs account description'
  o.expires_at { Time.zone.now + 1.month }
  o.created_by 0
end 

Factory.define_default :account_user, :class => AccountUser do |o|
  o.user_role 'Owner'
  o.created_by 0
end

Factory.define_default :price_group, :class => PriceGroup do |o|
  o.sequence(:name) { |n| "Price Group #{n}" }
  o.display_order 999
  o.is_internal true
end

Factory.define_default :user_price_group_member, :class => UserPriceGroupMember do |o|
end

Factory.define_default :account_price_group_member, :class => AccountPriceGroupMember do |o|
end

Factory.define_default :instrument, :class => Instrument do |o|
  o.sequence(:name) { |n| "Instrument #{n}" }
  o.sequence(:url_name) { |n| "instrument#{n}"  }
  o.description 'Lorem ipsum...'
  o.account 51234
  o.requires_approval false
  o.is_archived false
  o.is_hidden false
  o.initial_order_status_id { |o| find_order_status('New').id }
  o.min_reserve_mins 60
  o.max_reserve_mins 120
end

Factory.define_default :relay, :class => Relay do |o|
  o.type 'RelaySynaccessRevA'
  o.ip '192.168.1.1'
  o.sequence(:port) {|p| p }
  o.sequence(:username) {|n| "username#{n}" }
  o.sequence(:password) {|n| "password#{n}" }
end

Factory.define_default :relay_syna, :class => RelaySynaccessRevA do |o|
  o.ip '192.168.1.1'
  o.sequence(:port) {|p| p }
  o.sequence(:username) {|n| "username#{n}" }
  o.sequence(:password) {|n| "password#{n}" }
end

Factory.define_default :relay_synb, :class => RelaySynaccessRevB do |o|
  o.ip '192.168.1.2'
  o.sequence(:port) {|p| p }
  o.sequence(:username) {|n| "username#{n}" }
  o.sequence(:password) {|n| "password#{n}" }
end

Factory.define_default :relay_dummy, :class => RelayDummy do |o|
end

Factory.define_default :instrument_status do |o|
  o.is_on true
end

Factory.define_default :product_access_group do |o|
  o.sequence(:name) { |n| "Level #{n}" }
end

Factory.define_default :instrument_price_policy, :class => InstrumentPricePolicy do |o|
  o.unit_cost 1
  o.unit_subsidy 0
  o.reservation_rate 1
  o.reservation_subsidy 0
  o.reservation_mins 1
  o.minimum_cost 1
  o.usage_mins 1
  o.overage_mins 1
  o.can_purchase true
  o.start_date { Time.zone.now.beginning_of_day }
  o.expire_date { PricePolicy.generate_expire_date(Time.zone.now.beginning_of_day) }
end

Factory.define_default :item, :class => Item do |o|
  o.sequence(:name) { |n| "Item #{n}" }
  o.sequence(:url_name) { |n| "item_url_#{n}" }
  o.description       'Lorem ipsum...'
  o.account           51234
  o.requires_approval false
  o.is_archived       false
  o.is_hidden         false
  o.initial_order_status_id { |o| find_order_status('New').id }
end

Factory.define_default :item_price_policy, :class => ItemPricePolicy do |o|
  o.can_purchase true
  o.unit_cost 1
  o.unit_subsidy 0
  o.start_date { Time.zone.now.beginning_of_day }
  o.expire_date { PricePolicy.generate_expire_date(Date.today) }
end

Factory.define_default :service, :class => Service do |o|
  o.sequence(:name) { |n| "Service #{n}" }
  o.sequence(:url_name) { |n| "service#{n}" }
  o.account 51234
  o.requires_approval false
  o.is_archived false
  o.is_hidden false
  o.initial_order_status_id { |o| find_order_status('New').id }
end

Factory.define_default :bundle do |b|
  b.sequence(:name) {|n| "Bundle #{n}" }
  b.sequence(:url_name) {|n| "bundle-#{n}" }
  b.requires_approval false
  b.is_archived false
  b.is_hidden false
end

Factory.define_default :order_status, :class => OrderStatus do |o|
  o.sequence(:name) { |n| "Status #{n}" }
end

Factory.define_default :service_price_policy, :class => ServicePricePolicy do |o|
  o.can_purchase true
  o.unit_cost 1
  o.unit_subsidy 0
  o.start_date { Time.zone.now.beginning_of_day }
  o.expire_date { PricePolicy.generate_expire_date(Date.today) }
end

Factory.define_default :schedule_rule, :class => ScheduleRule do |o|
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

Factory.define_default :payment_account_transaction do |pat|
  pat.description 'fake trans'
  pat.transaction_amount -12.34
  pat.finalized_at { Time.zone.now }
  pat.reference 'abc123xyz'
  pat.is_in_dispute false
end

Factory.define_default :statement do |s|
end

Factory.define_default :statement_row do |s|
  s.amount 5
end

Factory.define_default :reservation do |r|
  r.reserve_start_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day }
  r.reserve_end_at { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day + 1.hour }
end

Factory.define_default :journal do |j|
  j.is_successful true
end

Factory.define_default :file_upload do |f|
  f.swf_uploaded_data fixture_file_upload("#{Rails.root}/spec/files/flash_file.swf", 'application/x-shockwave-flash')
  f.name "#{Rails.root}/spec/files/flash_file.swf"
  f.file_type 'info'
end

Factory.define_default :response_set do |s|
  s.sequence(:access_code) { |n| "#{n}#{n}#{n}" }
end

Factory.define_default :price_group_product do |pgp|
  pgp.reservation_window 1
end