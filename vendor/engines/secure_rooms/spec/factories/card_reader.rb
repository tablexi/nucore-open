FactoryBot.define do
  factory :card_reader, class: SecureRooms::CardReader do
    secure_room
    sequence(:card_reader_number) { |n| "card_reader_#{n}" }
    # Generate a sequential MAC address
    sequence(:control_device_number) { |n| format("%012X", n).scan(/.{2}/).join(":") }
    ingress { true }

    trait :exit do
      ingress { false }
    end
  end
end
