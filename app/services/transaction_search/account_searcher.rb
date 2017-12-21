module TransactionSearch

  class AccountSearcher < BaseSearcher

    def options
      Account.select("accounts.id, accounts.account_number, accounts.description, accounts.type")
             .where(id: order_details.select("distinct order_details.account_id"))
             .order(:account_number, :description)
    end

    def search(params)
      order_details.for_accounts(params)
    end

    def optimized
      order_details.includes(:account)
    end

    def label_method
      :account_list_item
    end

  end

end
