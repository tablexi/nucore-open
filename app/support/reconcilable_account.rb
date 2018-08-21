# frozen_string_literal: true

module ReconcilableAccount

  extend ActiveSupport::Concern

  module ClassMethods

    def need_reconciling(facility)
      accounts = joins(:order_details).merge(OrderDetail.complete.statemented(facility))
      where(id: accounts.distinct.pluck(:id))
    end

  end

end
