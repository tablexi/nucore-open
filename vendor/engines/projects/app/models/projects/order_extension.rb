module Projects

  module OrderExtension

    extend ActiveSupport::Concern

    included do
      around_save :assign_project_to_order_details
    end

    def project_id
      @project_id ||= first_order_detail_with_project.try(:project_id)
    end

    def project_id=(new_project_id)
      @project_id = new_project_id
    end

    private

    def assign_project_to_order_details
      yield
      order_details.each do |order_detail|
        order_detail.update_attributes(project_id: project_id) ||
          raise(ActiveRecord::Rollback)
      end
    end

    def first_order_detail_with_project
      order_details.where("project_id IS NOT NULL").first
    end

  end

end
