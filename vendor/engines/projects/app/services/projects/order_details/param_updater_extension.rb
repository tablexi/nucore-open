# frozen_string_literal: true

module Projects

  module OrderDetails

    module ParamUpdaterExtension

      extend ActiveSupport::Concern

      included do
        permitted_attributes.unshift(:project_id)
      end

    end

  end

end
