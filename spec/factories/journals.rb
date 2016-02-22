FactoryGirl.define do
  factory :journal do
    is_successful true
    created_by 1
    journal_date { Time.zone.now }
  end
end
