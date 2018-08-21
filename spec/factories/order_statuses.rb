# frozen_string_literal: true

FactoryBot.define do
  factory :order_status do
    facility { nil }
    parent { nil }
    sequence(:name) { |n| "Status #{n}" }

    initialize_with do
      OrderStatus.find_or_create_by(
        facility: facility,
        name: name,
        parent: parent,
      )
    end
  end
end
