# frozen_string_literal: true

FactoryBot.define do
  factory :product_user do
    approved_by_user { build_stubbed(:user) }

    approved_at { Time.current }
  end
end
