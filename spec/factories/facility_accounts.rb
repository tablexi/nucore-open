FactoryGirl.define do
  factory :facility_account do
    revenue_account 41234
    sequence(:account_number) do |n|
      # This sequence was often running into blacklist problems
      # s = "1#{n%10}#{rand(10)}-7777777" # fund3-dept7
      s = "134-7#{"%06d" % n}"
      define_open_account(41234, s)
      s
    end

    is_active true
    created_by 1
  end
end
