class TransactionsController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as

  include TransactionSearch

  def initialize
    @active_tab = "accounts"
    super
  end

  def index_with_search
    @recently_reviewed = administered_order_details.recently_reviewed.paginate(page: params[:page])
    @order_details = administered_order_details.all_in_review
    @extra_date_column = :reviewed_at
    @order_detail_link = {
      text: text("shared.dispute"),
      display?: proc { |order_detail| order_detail.can_dispute? },
      proc: proc { |order_detail| order_order_detail_path(order_detail.order, order_detail) },
    }
  end

  private

  def administered_accounts
    Account.administered_by(current_user)
  end

  def administered_order_details
    @administered_order_details ||=
      OrderDetail.where(account_id: administered_accounts)
  end

end
