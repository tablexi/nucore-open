class InstrumentRelaysController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :init_product
  before_action :manage

  layout "two_column"

  # GET /facilities/:facility_id/instrument/:instrument_id/relays
  def index
  end

  # GET /facilities/:facility_id/instrument/:instrument_id/relays/:id/edit
  def edit
  end

  def update
  end

  def new
  end

  private

  def init_product
    id_param = params.except(:facility_id).keys.detect { |k| k.end_with?("_id") }
    @product = current_facility.products
                               .of_type(Instrument)
                               .find_by!(url_name: params[id_param])
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

end
