# frozen_string_literal: true

module Projects

  module OrderDetailBatchUpdaterExtension

    extend ActiveSupport::Concern

    included do
      permitted_attributes.unshift(:project_id)
    end

  end

end
