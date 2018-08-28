# frozen_string_literal: true

FactoryBot.define do
  factory :product_access_group do
    sequence(:name) { |n| "Level #{n}" }
  end
end
