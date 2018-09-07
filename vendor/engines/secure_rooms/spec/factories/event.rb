# frozen_string_literal: true

FactoryBot.define do
  factory :event, class: SecureRooms::Event do
    occurred_at { Time.current }
    card_reader
    user
    outcome { :deny }
    card_number { "12345" }

    trait :successful do
      outcome { :grant }
    end
  end
end
