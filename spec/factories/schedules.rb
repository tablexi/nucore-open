# frozen_string_literal: true

FactoryBot.define do
  factory :schedule do
    sequence(:name) { |n| "Schedule #{n}" }
    facility factory: :setup_facility
  end
end
