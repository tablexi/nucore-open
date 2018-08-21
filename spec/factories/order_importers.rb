# frozen_string_literal: true

FactoryBot.define do
  factory :order_import do
    facility
    association :creator, factory: :user
    association :upload_file, factory: :csv_stored_file
  end
end
