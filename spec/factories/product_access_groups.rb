FactoryBot.define do
  factory :product_access_group do
    sequence(:name) { |n| "Level #{n}" }
  end
end
