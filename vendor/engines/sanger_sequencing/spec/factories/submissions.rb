# frozen_string_literal: true

FactoryBot.define do
  factory :sanger_sequencing_submission, class: SangerSequencing::Submission do
    transient do
      sample_count { 0 }
    end

    after(:build) do |submission, evaluator|
      evaluator.sample_count.times { |i| submission.samples.build(customer_sample_id: "sample #{i}") }
    end
  end
end
