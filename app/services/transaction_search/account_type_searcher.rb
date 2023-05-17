# frozen_string_literal: true

module TransactionSearch

  class AccountTypeSearcher < BaseSearcher

    def options
      Account.config.account_types.map(&:constantize)
    end

    def search(params)
      order_details.where("accounts.type" => params).includes(:account)
    end

    def label_method
      :type_string
    end

    def label
      "Account Type"
    end

  end

end
