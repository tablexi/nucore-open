class InstrumentsController < ProductsCommonController

  customer_tab :show, :public_schedule
  admin_tab :create, :new, :edit, :index, :manage, :update, :manage, :schedule
  before_action :store_fullpath_in_session, only: [:index, :show]
  before_action :set_default_lock_window, only: [:create, :update]

  # public_schedule does not require login
  skip_before_action :authenticate_user!, only: [:public_schedule]
  skip_authorize_resource only: [:public_schedule]

  skip_before_action :init_product, only: [:instrument_statuses]

  # GET /facilities/:facility_id/instruments/:instrument_id
  def show
    assert_product_is_accessible!
    add_to_cart = true
    login_required = false

    # does the product have active price policies and schedule rules?
    unless @instrument.available_for_purchase?
      add_to_cart = false
      flash[:notice] = text(".not_available", instrument: @instrument)
    end

    # is user logged in?
    if add_to_cart && acting_user.blank?
      login_required = true
      add_to_cart = false
    end

    if add_to_cart && !@instrument.can_be_used_by?(acting_user) && !session_user_can_override_restrictions?(@instrument)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(current_user, @instrument)
          flash[:notice] = text("controllers.products_common.already_requested_access", product: @instrument)
          return redirect_to facility_path(current_facility)
        else
          return redirect_to new_facility_product_training_request_path(current_facility, @instrument)
        end
      else
        add_to_cart = false
        flash[:notice] = html(".requires_approval",
                              email: @instrument.email,
                              facility: @instrument.facility,
                              instrument: @instrument)
      end
    end

    # does the user have a valid payment source for purchasing this reservation?
    if add_to_cart && acting_user.accounts_for_product(@instrument).blank?
      add_to_cart = false
      flash[:notice] = text(".no_accounts")
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if add_to_cart && !acting_user_can_purchase?
      add_to_cart = false
      flash[:notice] = text(".no_price_groups", instrument_name: @instrument.to_s)
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if add_to_cart && acting_as? && !session_user.operator_of?(@instrument.facility)
      add_to_cart = false
      flash[:notice] = text(".not_authorized_to_order_on_behalf")
    end

    @add_to_cart = add_to_cart

    if login_required
      return redirect_to new_user_session_path
    elsif !add_to_cart
      return redirect_to facility_path(current_facility)
    end

    redirect_to add_order_path(
      acting_user.cart(session_user),
      order: { order_details: [{ product_id: @instrument.id, quantity: 1 }] },
    )
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/schedule
  def schedule
    @admin_reservations =
      @instrument
      .reservations
      .non_user
      .ends_in_the_future
      .order(:reserve_start_at)
  end

  def public_schedule
    render layout: "application"
  end

  def set_default_lock_window
    if params[:instrument][:lock_window].blank?
      params[:instrument][:lock_window] = 0
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/status
  def instrument_status
    begin
      @relay = @instrument.relay
      status = Rails.env.test? ? true : @relay.get_status
      @status = @instrument.instrument_statuses.create!(is_on: status)
    rescue => e
      logger.error e
      raise ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.html  { render layout: false }
      format.json  { render json: @status }
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
        @instrument_statuses << if instrument_status && status == instrument_status.is_on?
                                  instrument_status
                                else
                                  # || false will ensure that the value of is_on is not nil (causes a DB error)
                                  instrument.instrument_statuses.create!(is_on: status || NUCore::Database.boolean(false))
                                end
      rescue => e
        logger.error e.message
        @instrument_statuses << InstrumentStatus.new(instrument: instrument, error_message: e.message)
      end
    end
    render json: @instrument_statuses
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/switch
  def switch
    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == "on" || params[:switch] == "off")

    begin
      relay = @instrument.relay
      status = true

      if SettingsHelper.relays_enabled_for_admin?
        status = (params[:switch] == "on" ? relay.activate : relay.deactivate)
      end

      @status = @instrument.instrument_statuses.create!(is_on: status)
    rescue => e
      logger.error "ERROR: #{e.message}"
      @status = InstrumentStatus.new(instrument: @instrument, error_message: e.message)
      # raise ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.html { render action: :instrument_status, layout: false }
      format.json { render json: @status }
    end
  end

  protected

  def translation_scope
    "controllers.instruments"
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
