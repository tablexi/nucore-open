FactoryGirl.define do
  factory :training_request do
    user
    association :product, factory: :instrument_requiring_approval
  end
end
