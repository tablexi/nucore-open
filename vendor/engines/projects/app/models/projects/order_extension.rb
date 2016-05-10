module Projects

  module OrderExtension

    extend ActiveSupport::Concern

    included do
      before_save :assign_project_to_order_details
      attr_writer :project_id
    end

    def project_id
      @project_id ||= order_details.where("project_id IS NOT NULL").pluck(:project_id).first
    end

    private

    def assign_project_to_order_details
      order_details.each { |order_detail| order_detail.project_id = project_id }
    end

  end

end
