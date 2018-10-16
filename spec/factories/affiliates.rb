# frozen_string_literal: true

FactoryBot.define do
  factory :affiliate do
    sequence(:name) { |n| "Affiliate #{n}" }
  end
end
