# frozen_string_literal: true

FactoryBot.define do
  factory :ability do
    skip_create

    user
    facility
    stub_controller { OpenStruct.new }

    initialize_with do
      Ability.new(user, facility, stub_controller)
    end
  end
end
