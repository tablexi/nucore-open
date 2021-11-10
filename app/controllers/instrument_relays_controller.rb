class InstrumentRelaysController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_product
  before_action :init_relay, only: [:edit, :new, :update, :create]
  before_action :manage

  layout "two_column"

  # GET /facilities/:facility_id/instrument/:instrument_id/relays
  def index
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/:id/edit
  def edit
    @relay_submit_url = facility_instrument_relay_path(current_facility, @product, @relay)
    @relay_submit_method = :patch
  end

  def update
    respond_to do |format|
      if @relay.update(relay_params.except(:control_mechanism))
        flash[:notice] = "Relay was successfully updated."
        format.html { redirect_to([current_facility, @product, Relay]) }
      else
        @relay_submit_url = facility_instrument_relay_path(current_facility, @product, @relay)
        @relay_submit_method = :patch
        format.html { render action: "edit" }
      end
    end
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/new
  def new
    @relay_submit_url = facility_instrument_relays_path(current_facility, @product)
    @relay_submit_method = :post
  end

  def create
    @relay = @product.build_relay(relay_params.except(:control_mechanism))
    respond_to do |format|
      if @product.save
        flash[:notice] = "Relay was successfully added."
        format.html { redirect_to([current_facility, @product, Relay]) }
      else
        @relay_submit_url = facility_instrument_relays_path(current_facility, @product)
        @relay_submit_method = :post
        format.html { render action: "new" }
      end
    end
  end

  private

  def init_product
    @product = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def init_relay
    @relay = @product.relay || @product.build_relay
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

  def relay_params
    params.require(:relay).permit(:control_mechanism, :ip, :ip_port, :outlet, :username, :password, :type, :auto_logout, :auto_logout_minutes, :id, 
                                                                        :mac_address, :building_room_number, :circuit_number, :ethernet_port_number)
  end

end
