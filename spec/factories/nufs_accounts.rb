FactoryGirl.define do
  factory :nufs_account do
    sequence(:account_number) do |n|
      "9#{n%10}#{rand(10)}-7777777" # fund3-dept7
    end

    description 'nufs account description'
    expires_at { Time.zone.now + 1.month }
    created_by 0
  end
end 
