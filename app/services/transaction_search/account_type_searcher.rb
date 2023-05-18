# frozen_string_literal: true

module TransactionSearch

  class AccountTypeSearcher < BaseSearcher

    def options
      Account.config.account_types.map(&:constantize)
    end

    def search(params)
      order_details.for_account_types(params).references(:account).includes(:account)
    end

    def label_method
      :type_string
    end

    def label
      "Account Types"
    end

  end

end
