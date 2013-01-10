overridable_factory :nufs_account do
  sequence(:account_number) do |n|
    "9#{'%02d' % n}-7777777" # fund3-dept7
  end

  description 'nufs account description'
  expires_at { Time.zone.now + 1.month }
  created_by 0
end

