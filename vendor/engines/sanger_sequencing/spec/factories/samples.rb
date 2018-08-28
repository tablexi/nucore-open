# frozen_string_literal: true

FactoryBot.define do
  factory :sanger_sequencing_sample, class: SangerSequencing::Sample do
    after(:stub) do |sample, _evaluator|
      sample.customer_sample_id = sample.form_customer_sample_id
    end
  end
end
