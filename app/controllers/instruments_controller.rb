class InstrumentsController < ProductsCommonController
  customer_tab  :show, :public_schedule
  admin_tab     :create, :edit, :index, :manage, :new, :schedule, :update

  # public_schedule does not require login
  skip_before_filter :authenticate_user!, :only => [:public_schedule]
  skip_authorize_resource :only => [:public_schedule]

  skip_before_filter :init_product, :only => [:instrument_statuses]

  # GET /instruments
  def index
    super
    # find current and next upcoming reservations for each instrument
    @reservations = {}
    @instruments.each { |i| @reservations[i.id] = i.reservations.upcoming[0..2]}
  end

  # GET /instruments/1
  def show
    assert_product_is_accessible!
    add_to_cart = true
    login_required = false

    # do the product have active price policies && schedule rules
    unless @instrument.available_for_purchase?
      add_to_cart = false
      flash[:notice] = t_model_error(Instrument, 'not_available', :instrument => @instrument)
    end

    # is user logged in?
    if add_to_cart && acting_user.nil?
      login_required = true
      add_to_cart = false
    end

    # is the user approved? or is the logged in user an operator of the facility (logged in user can override restrictions)
    if add_to_cart && !@instrument.is_approved_for?(acting_user)
      add_to_cart = false unless session_user and session_user.can_override_restrictions?(@instrument)
      flash[:notice] = t_model_error(Instrument, 'requires_approval_html', :instrument => @instrument, :facility => @instrument.facility, :email => @instrument.email).html_safe
    end

    # does the user have a valid payment source for purchasing this reservation?
    if add_to_cart && acting_user.accounts_for_product(@instrument).blank?
      add_to_cart=false
      flash[:notice]=t_model_error @instrument.class, 'no_accounts'
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if add_to_cart && !(@instrument.can_purchase?((acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect{ |pg| pg.id }))
      add_to_cart = false
      flash[:notice] = "You are not in a price group that may reserve instrument #{@instrument.to_s}; please contact the facility."
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if add_to_cart && acting_as? && !session_user.operator_of?(@instrument.facility)
      add_to_cart = false
      flash[:notice] = 'You are not authorized to order instruments from this facility on behalf of a user.'
    end
    @add_to_cart = add_to_cart

    if login_required
      session[:requested_params]=request.fullpath
      return redirect_to new_user_session_path
    elsif !add_to_cart
      return redirect_to facility_path(current_facility)
    end

    redirect_to add_order_path(acting_user.cart(session_user), :order => {:order_details => [{:product_id => @instrument.id, :quantity => 1}]})
  end

  # PUT /instruments/1
  def update
    @header_prefix = "Edit"

    if @instrument.update_attributes(params[:instrument])
      flash[:notice] = 'Instrument was successfully updated.'
      return redirect_to(manage_facility_instrument_path(current_facility, @instrument))
    end

    render :action => "edit"
  end

  # GET /instruments/1/schedule
  def schedule
    @admin_reservations = @instrument.schedule.reservations.find(:all, :conditions => ['reserve_end_at > ? AND order_detail_id IS NULL', Time.zone.now])
  end

  def public_schedule
    render :layout => 'application'
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

      unless Rails.env.test?
        port=@instrument.relay.port
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
end
