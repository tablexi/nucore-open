# frozen_string_literal: true

class InstrumentIssuesController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  before_action :init_product
  before_action :init_instrument_issue, only: %i[new create]

  def new
  end

  def create
    @instrument_issue.assign_attributes(create_params)
    if @instrument_issue.send_notification
      redirect_to reservations_path, notice: text("create.success")
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:instrument_issue).permit(:message)
  end

  def init_product
    @product = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def init_instrument_issue
    @instrument_issue = InstrumentIssue.new(product: @product, user: current_user)
  end

end
