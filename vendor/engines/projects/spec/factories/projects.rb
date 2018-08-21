# frozen_string_literal: true

FactoryBot.define do
  factory :project, class: Projects::Project do
    sequence(:name) { |n| "Project #{n}" }
    facility

    trait :inactive do
      active { false }
    end
  end
end
