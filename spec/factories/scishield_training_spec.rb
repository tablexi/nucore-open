# frozen_string_literal: true

FactoryBot.define do
  factory :scishield_training do
    user_id { 1 }
    sequence(:course_name) { |n| "Scishield Course Name #{n}" }
  end
end
