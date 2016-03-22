FactoryGirl.define do
  factory :journal_row do
    account { 99_999 }
    amount { 100 }
    journal
    order_detail
  end
end
