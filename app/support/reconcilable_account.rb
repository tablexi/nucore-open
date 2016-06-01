module ReconcilableAccount

  extend ActiveSupport::Concern

  module ClassMethods

    def need_reconciling(facility)
      accounts = OrderDetail.unreconciled_accounts(facility, model_name.name)
      where(id: accounts.pluck(:account_id))
    end

  end

end
