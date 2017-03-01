FactoryGirl.define do
  factory :card_reader, class: CardReader do
    control_device
    entrance true
  end
end
