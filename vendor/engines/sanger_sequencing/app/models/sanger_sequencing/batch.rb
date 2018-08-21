# frozen_string_literal: true

module SangerSequencing

  class Batch < ApplicationRecord

    DEFAULT_PRODUCT_GROUP_NAME = [nil, ""].freeze

    self.table_name = "sanger_sequencing_batches"

    belongs_to :created_by, class_name: "User"
    belongs_to :facility
    has_many :submissions, class_name: "SangerSequencing::Submission", inverse_of: :batch, dependent: :nullify
    has_many :samples, class_name: "SangerSequencing::Sample", through: :submissions

    serialize :well_plates_raw

    def self.for_facility(facility)
      where(facility: facility)
    end

    def self.for_product_group(product_group_name)
      product_group_name = DEFAULT_PRODUCT_GROUP_NAME if product_group_name.blank?
      where(group: product_group_name)
    end

    def well_plates
      well_plates_raw.map { |well_plate| WellPlate.new(well_plate, samples: samples) }
    end

    def sample_at(well_plate_index, cell_name)
      well_plates[well_plate_index][cell_name]
    end

  end

end
