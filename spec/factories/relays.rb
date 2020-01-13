# frozen_string_literal: true

FactoryBot.define do
  factory :relay do
    type { "RelaySynaccessRevA" }
    ip { "192.168.1.1" }
    sequence(:outlet) { |o| o }
    sequence(:username) { |n| "username#{n}" }
    sequence(:password) { |n| "password#{n}" }

    factory :relay_syna, class: RelaySynaccessRevA do
    end

    factory :relay_synb, class: RelaySynaccessRevB do
      type { "RelaySynaccessRevB" }
    end
  end

  factory :relay_dummy, class: RelayDummy do
    type { "RelayDummy" }
  end
end
