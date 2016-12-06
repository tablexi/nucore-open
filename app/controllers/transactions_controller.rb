class TransactionsController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as

  include TransactionSearch

  def initialize
    @active_tab = "accounts"
    super
  end

  def in_review_with_search
    @recently_reviewed = current_user.administered_order_details.recently_reviewed.paginate(page: params[:page])
    @order_details = current_user.administered_order_details.all_in_review
    @extra_date_column = :reviewed_at
    @order_detail_link = {
      text: text("shared.dispute"),
      display?: proc { |order_detail| order_detail.can_dispute? },
      proc: proc { |order_detail| order_order_detail_path(order_detail.order, order_detail) },
    }
  end

end
