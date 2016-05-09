module Projects

  module OrdersControllerExtension

    extend ActiveSupport::Concern

    included do
      before_order_detail_update_hooks << :update_project_id!
    end

    def update_project_id!
      if acting_as? && params[:order].present?
        @order.project_id = params[:order][:project_id]
        @order.save!
      end
    end

  end

end
