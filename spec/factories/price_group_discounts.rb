# frozen_string_literal: true

FactoryBot.define do
  factory :price_group_discount do
    price_group { nil }
    schedule_rule { nil }
    discount_percent { "9.99" }
  end
end
