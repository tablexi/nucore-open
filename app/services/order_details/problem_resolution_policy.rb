module OrderDetails

  class ProblemResolutionPolicy

    attr_reader :order_detail

    def initialize(order_detail)
      @order_detail = order_detail
    end

    def user_can_resolve?
      [
        order_detail.problem?,
        order_detail.requires_but_missing_actuals?,
        order_detail.product.problems_resolvable_by_user?,
      ].all?
    end

  end

end
