module Projects

  module OrderDetailExtension

    extend ActiveSupport::Concern

    included do
      belongs_to :project,
                 class_name: "Projects::Project",
                 foreign_key: :project_id,
                 inverse_of: :order_details

      validate :project_facility_matches?
    end

    private

    def project_facility_matches?
      if project_id.present? && project.facility != facility
        errors.add(:project_id, :project_facility_mismatch)
      end
    end

  end

end
