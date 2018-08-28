# frozen_string_literal: true

FactoryBot.define do
  factory :sanger_sequencing_batch, class: SangerSequencing::Batch do
    well_plates_raw { [] }
  end
end
