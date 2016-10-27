module BulkEmail

  module FacilityExtension

    extend ActiveSupport::Concern

    included do
      has_many :bulk_email_jobs,
               class_name: "BulkEmail::Job",
               foreign_key: :facility_id,
               inverse_of: :facility,
               dependent: :destroy # Though Facilities cannot be destroyed
    end

  end

end
