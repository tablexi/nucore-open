module OrderDetails

  class Reconciler
    attr_reader :errors, :count

    def initialize(order_detail_scope, params)
      @order_details = order_detail_scope.readonly(false).find(params.keys)
      @params = params
    end

    def reconcile_all
      @count = 0
      OrderDetail.transaction do
        @order_details.each do |od|
          od_params = @params[od.id.to_s]
          reconcile(od, od_params)
        end
      end
      @count
    end

    private

    def reconcile(order_detail, params)
      return unless params[:reconciled] == "1"

      order_detail.assign_attributes(allowed(params))
      order_detail.change_status!(OrderStatus.reconciled_status)
      @count += 1
    rescue => e
      @error_fields = { order_detail.id => order_detail.errors.collect { |field, _error| field } }
      @errors = order_detail.errors.full_messages
      @errors = [e.message] if @errors.empty?
      @count = 0
      raise ActiveRecord::Rollback
    end

    def allowed(params)
      params.permit(:reconciled_note)
    end

  end

end
