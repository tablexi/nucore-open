FactoryGirl.define do
  factory :project, class: Projects::Project do
    sequence(:name) { |n| "Project #{n}" }
    facility

    trait :archived do
      active false
    end
  end
end
