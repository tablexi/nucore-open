class InstrumentsController < ProductsCommonController
  customer_tab  :show, :public_schedule
  admin_tab     :create, :edit, :index, :manage, :new, :schedule, :update

  before_filter :store_fullpath_in_session, only: [:index, :show]
  before_filter :set_default_lock_window, only: [:create, :update]

  # public_schedule does not require login
  skip_before_filter :authenticate_user!, :only => [:public_schedule]
  skip_authorize_resource :only => [:public_schedule]

  skip_before_filter :init_product, :only => [:instrument_statuses]

  # GET /facilities/:facility_id/instruments
  def index
    super
    # find current and next upcoming reservations for each instrument
    @reservations = {}
    @instruments.each { |i| @reservations[i.id] = i.reservations.upcoming[0..2]}
  end

  # GET /facilities/:facility_id/instruments/:instrument_id
  def show
    @show_product = ShowProduct.new(self, @instrument, acting_user, session_user, acting_as?)
    user_may_add_product_to_cart = @show_product.able_to_add_to_cart?
    error = @show_product.error

    flash[:notice] = error if error.present?

    if @show_product.login_required
      return redirect_to new_user_session_path
    elsif !user_may_add_product_to_cart
      return redirect_to @show_product.redirect || facility_path(current_facility)
    end

    redirect_to add_order_path(
      acting_user.cart(session_user),
      order: { order_details: [ { product_id: @instrument.id, quantity: 1} ] },
    )
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id
  def update
    @header_prefix = "Edit"

    if @instrument.update_attributes(params[:instrument])
      flash[:notice] = 'Instrument was successfully updated.'
      return redirect_to(manage_facility_instrument_path(current_facility, @instrument))
    end

    render :action => "edit"
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/schedule
  def schedule
    @admin_reservations = @instrument.schedule.reservations.where('reserve_end_at > ? AND order_detail_id IS NULL', Time.zone.now).order("reserve_start_at ASC")
  end

  def public_schedule
    render :layout => 'application'
  end

  def set_default_lock_window
    if params[:instrument][:lock_window].blank?
      params[:instrument][:lock_window] = 0
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/status
  def instrument_status
    begin
      @relay  = @instrument.relay
      status = Rails.env.test? ? true : @relay.get_status
      @status = @instrument.instrument_statuses.create!(:is_on => status)
    rescue => e
      logger.error e
      raise ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.html  { render :layout => false }
      format.json  { render :json => @status }
    end
  end

  def instrument_statuses
    @instrument_statuses = []
    current_facility.instruments.order(:id).includes(:relay).each do |instrument|
      # skip instruments with no relay
      next unless instrument.relay

      # skip instruments with dummy relay
      # next if instrument.relay.is_a? RelayDummy

      begin
        status = instrument.relay.get_status
        instrument_status = instrument.current_instrument_status
        # if the status hasn't changed, don't create a new status
        if instrument_status && status == instrument_status.is_on?
          @instrument_statuses << instrument_status
        else
          # || false will ensure that the value of is_on is not nil (causes a DB error)
          @instrument_statuses << instrument.instrument_statuses.create!(:is_on => status || NUCore::Database.boolean(false))
        end
      rescue => e
        logger.error e.message
        @instrument_statuses << InstrumentStatus.new(:instrument => instrument, :error_message => e.message)
      end
    end
    render :json => @instrument_statuses
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/switch
  def switch
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == 'on' || params[:switch] == 'off')

    begin
      relay = @instrument.relay
      status=true

      if SettingsHelper.relays_enabled_for_admin?
        status = (params[:switch] == 'on' ? relay.activate : relay.deactivate)
      end

      @status = @instrument.instrument_statuses.create!(:is_on => status)
    rescue => e
      logger.error "ERROR: #{e.message}"
      @status = InstrumentStatus.new(:instrument => @instrument, :error_message => e.message)
      #raise ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.html { render :action => :instrument_status, :layout => false }
      format.json { render :json => @status }
    end
  end

  private

  def acting_user_can_purchase?
    @instrument.can_purchase?(acting_user_price_group_ids)
  end

  def acting_user_price_group_ids
    (acting_user.price_groups + acting_user.account_price_groups)
    .flatten
    .uniq
    .map(&:id)
  end
end
