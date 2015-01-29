class Api::OrderDetailsController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :order_detail_not_found

  http_basic_authenticate_with name: Settings.api.basic_auth_name, password: Settings.api.basic_auth_password

  def show
    render json: Api::OrderDetail.new(order_detail).to_h
  end

  private

  def order_detail
    @order_detail ||= OrderDetail.find(params[:id])
  end

  def order_detail_not_found
    render json: { error: "not found" }, status: 404
  end
end
