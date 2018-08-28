# frozen_string_literal: true

module Projects

  module FacilityExtension

    extend ActiveSupport::Concern

    included do
      has_many :projects,
               class_name: "Projects::Project",
               foreign_key: :facility_id,
               inverse_of: :facility,
               dependent: :destroy # Though Facilities cannot be destroyed
    end

  end

end
