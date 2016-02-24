class OrderSearchController < ApplicationController

  customer_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as

  def index
    @order_details = OrderSearcher.new(current_user).search(params[:search])
  end

end