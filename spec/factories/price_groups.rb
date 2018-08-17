FactoryBot.define do
  factory :price_group do
    facility
    sequence(:name, "AAAAAAAA") { |n| "Price Group #{n}" }
    display_order { 999 }
    is_internal { true }
    admin_editable { true }

    trait :skip_validations do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :global do
      # Global PriceGroups are technically invalid because they have no facility
      skip_validations
      facility { nil }
      admin_editable { false }
    end

    trait :cancer_center do
      global
      admin_editable { true }
    end
  end

  factory :price_group_product do
    reservation_window { 1 }
  end

end
