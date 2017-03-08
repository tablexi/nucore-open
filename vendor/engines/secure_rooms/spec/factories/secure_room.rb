FactoryGirl.define do
  factory :secure_room, class: SecureRoom, parent: :setup_product do
    sequence(:name) { |n| "Room #{n}" }
    sequence(:url_name) { |n| "Room#{n}" }
  end
end
