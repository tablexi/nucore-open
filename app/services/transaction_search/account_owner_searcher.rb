module TransactionSearch

  class AccountOwnerSearcher < BaseSearcher

    def options
      User.select("users.id, users.first_name, users.last_name")
          .where(id: order_details.select("distinct account_users.user_id").joins(account: :owner_user))
          .order(:last_name, :first_name)
    end

    def search(params)
      order_details.for_owners(params)
    end

    def optimized
      order_details.preload(account: :owner_user)
    end

  end

end
