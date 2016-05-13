module Projects

  module OrdersControllerExtension

    extend ActiveSupport::Concern

    included do
      permitted_acting_as_params.unshift(:project_id)
    end

  end

end
