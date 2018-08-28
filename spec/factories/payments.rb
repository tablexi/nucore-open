# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    source { :check }
  end
end
