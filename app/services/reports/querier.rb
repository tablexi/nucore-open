module Reports

  class Querier

    attr_reader :order_status_id, :current_facility, :date_range_field,
      :date_range_start, :date_range_end

    def initialize(options = {})
      @order_status_id = options[:order_status_id]
      @current_facility = options[:current_facility]
      @date_range_field = options[:date_range_field]
      @date_range_start = options[:date_range_start]
      @date_range_end = options[:date_range_end]
    end

    def perform
      OrderDetailListTransformerFactory.instance(order_details).perform
    end

    def order_details
      return [] if order_status_id.blank?
      OrderDetail.where(order_status_id: order_status_id)
        .for_facility(current_facility)
        .action_in_date_range(date_range_field, date_range_start, date_range_end)
        .includes(:order, :account, :price_policy, :product, :order_status)
    end

  end

end
