module TransactionSearch

  class OrderStatusSearcher < BaseSearcher

    def options
      OrderStatus.select("order_statuses.id, order_statuses.facility_id, order_statuses.name, order_statuses.lft")
                 .where(id: order_details.select("distinct order_details.order_status_id"))
                 .order("order_statuses.lft")
    end

    def search(params)
      order_details.for_order_statuses(params)
    end

    def optimized
      order_details.preload(:order_status)
    end

    def data_attrs(order_status)
      {}.tap do |h|
        h[:facility] = order_status.facility_id if order_status.facility_id
      end
    end

  end

end
