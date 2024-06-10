# frozen_string_literal: true

class InstrumentIssuesController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  before_action :init_order_detail
  before_action :init_product
  before_action :init_instrument_issue, only: %i[new create]
  layout -> { modal? ? false : "application" }

  def new
    redirect_to_order_id = params[:redirect_to_order_id]

    if modal?
      render partial: "instruments/actions/issues", locals: { product: @product, order_detail: @order_detail, instrument_issue: @instrument_issue, redirect_to_order_id: }
    end
  end

  def create
    @instrument_issue.assign_attributes(create_params)
    redirect_to_order_id = params[:redirect_to_order_id]

    if @instrument_issue.send_notification
      if redirect_to_order_id.present?
        order = Order.find(redirect_to_order_id)
        redirect_to facility_order_path(order.facility, order), notice: text("create.success")
      else
        redirect_to reservations_path, notice: text("create.success")
      end
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:instrument_issue).permit(:message)
  end

  def init_order_detail
    @order_detail = OrderDetail.find(params[:order_detail_id])
  end

  def init_product
    @product = @order_detail.product
  end

  def init_instrument_issue
    @instrument_issue = InstrumentIssue.new(product: @product,
                                            user: current_user,
                                            order_detail: @order_detail)
  end

  def modal?
    request.xhr?
  end
  helper_method :modal?
end
