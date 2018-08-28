# frozen_string_literal: true

module Projects

  module OrderExtension

    extend ActiveSupport::Concern

    included do
      attr_reader :project_id
    end

    def project_id=(project_id)
      @project_id = project_id
      order_details.each { |order_detail| order_detail.project_id = project_id }
    end

  end

end
