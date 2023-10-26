# frozen_string_literal: true

FactoryBot.define do
  factory :duration_rate do
    min_duration { 3 }
    rate { 60 }
  end

end
