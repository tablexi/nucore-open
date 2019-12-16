# frozen_string_literal: true

FactoryBot.define do
  factory :certificate, class: ResearchSafetyCertificate do
    sequence(:name) { |n| "Certificate #{n}" }
  end
end
