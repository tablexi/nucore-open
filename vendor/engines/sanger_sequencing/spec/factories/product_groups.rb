FactoryBot.define do
  factory :product_group, class: SangerSequencing::ProductGroup do
    product factory: :setup_service

    trait :default do
      group { :default }
    end

    trait :fragment do
      group { :fragment }
    end
  end
end
