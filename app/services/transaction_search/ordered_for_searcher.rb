module TransactionSearch

  class OrderedForSearcher < BaseSearcher

    def options
      User.select(:id, :first_name, :last_name)
          .where(id: order_details.select("distinct orders.user_id"))
          .order(:last_name, :first_name)
    end

    def search(params)
      order_details.for_users(params)
    end

    def label_method
      :full_name
    end

    def label
      Order.human_attribute_name(:user)
    end

  end

end
