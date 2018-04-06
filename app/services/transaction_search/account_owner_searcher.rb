module TransactionSearch

  class AccountOwnerSearcher < BaseSearcher

    # TODO: Remove :suspended_at once the old transaction search is gone
    def options
      User.select(:id, :first_name, :last_name, :suspended_at)
          .where(id: order_details.select("distinct account_users.user_id").joins(account: :owner_user))
          .order(:last_name, :first_name)
    end

    def search(params)
      order_details.for_owners(params)
    end

    def optimized
      order_details.preload(account: :owner_user)
    end

    def label_method
      [:full_name, suspended_label: false]
    end

    def label
      Account.human_attribute_name(:owner).pluralize
    end

  end

end
