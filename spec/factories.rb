# frozen_string_literal: true

require File.expand_path("factories_env", File.dirname(__FILE__))

FactoryBot.define do
  factory :price_group_discount do
    price_group { nil }
    schedule_rule { nil }
    discount_percent { "9.99" }
  end
  # Global trait
  trait :without_validation do
    to_create { |instance| instance.save(validate: false) }
  end
end
