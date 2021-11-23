class InstrumentRelaysController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_instrument
  before_action :init_relay, only: [:edit, :new, :update, :create]
  before_action :manage

  layout "two_column"

  # GET /facilities/:facility_id/instrument/:instrument_id/relays
  # This will return either 1 or 0 relays for the given instrument
  def index
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/:id/edit
  def edit
  end

  def update
    control_mechanism = relay_params["control_mechanism"]
    if control_mechanism == Relay::CONTROL_MECHANISMS[:relay]
      if @relay.update(relay_params.except(:control_mechanism))
        flash[:notice] = "Relay was successfully updated."
        redirect_to facility_instrument_relays_path(current_facility, @product)
      else
        render action: "edit"
      end
    else
      @relay&.destroy
      if control_mechanism == Relay::CONTROL_MECHANISMS[:timer]
        @product.relay = RelayDummy.new
      end
      flash[:notice] = "Relay was successfully updated."
      redirect_to facility_instrument_relays_path(current_facility, @product)
    end
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/new
  def new
  end

  def create
    control_mechanism = relay_params["control_mechanism"]
    if control_mechanism == Relay::CONTROL_MECHANISMS[:relay]
      @relay = @product.build_relay(relay_params.except(:control_mechanism))
    elsif control_mechanism == Relay::CONTROL_MECHANISMS[:timer]
      @relay&.destroy
      @product.relay = RelayDummy.new
    else
      @relay&.destroy
    end

    if @product.save
      flash[:notice] = "Relay was successfully added."
      redirect_to facility_instrument_relays_path(current_facility, @product)
    else
      render action: "new"
    end
  end

  private

  def init_instrument
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
