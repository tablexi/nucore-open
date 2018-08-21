# frozen_string_literal: true

FactoryBot.define do
  factory :event, class: SecureRooms::Event do
    occurred_at { Time.current }
    card_reader
    user
    outcome { :deny }

    trait :successful do
      outcome { :grant }
    end
  end
end
