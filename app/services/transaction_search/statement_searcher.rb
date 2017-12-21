module TransactionSearch

  class StatementSearcher < BaseSearcher

    def options
      Statement.where(id: order_details.pluck(:statement_id)).reorder(:account_id, :id)
    end

    def search(params)
      if params.present?
        order_details.where(statement_id: params)
      else
        order_details
      end
    end

    def label_method
      :invoice_number
    end

  end

end
