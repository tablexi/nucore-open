class FacilityUserReservationsController < ApplicationController

  admin_tab :all
  before_action :init_current_facility
  before_action :authenticate_user!
  before_action :check_acting_as

  load_and_authorize_resource class: Reservation

  layout "two_column"

  # GET /facilities/:facility_id/users/:user_id/reservations
  def index
    @user = User.find(params[:user_id])
    @order_details = @user.order_details
                          .reservations
                          .where("orders.facility_id": current_facility.id)
                          .where("orders.ordered_at IS NOT NULL")
                          .order("orders.ordered_at DESC")
                          .paginate(page: params[:page])
  end

end
