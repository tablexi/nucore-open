class ProductsCommonController < ApplicationController

  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_action :authenticate_user!, except: [:show]
  before_action :check_acting_as, except: [:show]
  before_action :init_current_facility
  before_action :init_product, except: [:index, :new, :create]
  before_action :store_fullpath_in_session

  include TranslationHelper

  load_resource except: [:show, :manage, :index], instance_name: :product
  authorize_resource except: [:show, :manage], instance_name: :product

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /services
  def index
    @archived_product_count     = current_facility_products.archived.length
    @not_archived_product_count = current_facility_products.not_archived.length
    @products = if params[:archived].nil? || params[:archived] != "true"
                  current_facility_products.not_archived
                else
                  current_facility_products.archived
                end

    render "admin/products/index"
  end

  # GET /facilities/:facility_id/(services|items|bundles)/:(service|item|bundle)_id
  # TODO InstrumentsController#show has a lot in common; refactor/extract/consolidate
  def show
    assert_product_is_accessible!
    add_to_cart = true
    @login_required = false

    # does the product have active price policies?
    unless @product.available_for_purchase?
      add_to_cart = false
      @error = "not_available"
    end

    # is user logged in?
    if add_to_cart && acting_user.blank?
      @login_required = true
      add_to_cart = false
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if add_to_cart && acting_as? && !session_user.operator_of?(@product.facility)
      add_to_cart = false
      @error = "not_authorized_acting_as"
    end

    # does the user have a valid payment source for purchasing this reservation?
    if add_to_cart && acting_user.accounts_for_product(@product).blank?
      add_to_cart = false
      @error = "no_accounts"
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if add_to_cart && !price_policy_available_for_product?
      add_to_cart = false
      @error = "not_in_price_group"
    end

    # is the user approved?
    if add_to_cart && !@product.can_be_used_by?(acting_user) && !session_user_can_override_restrictions?(@product)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, @product)
          flash[:notice] = text(".already_requested_access", product: @product)
          return redirect_to facility_path(current_facility)
        else
          return redirect_to new_facility_product_training_request_path(current_facility, @product)
        end
      else
        add_to_cart = false
        @error = "requires_approval"
      end
    end

    if @error
      flash.now[:notice] = text(@error, singular: @product.class.model_name.to_s.downcase,
                                        plural: @product.class.model_name.human(count: 2).downcase)
    end

    @add_to_cart = add_to_cart
    @active_tab = "home"
    render layout: "application"
  end

  # GET /services/new
  def new
    @product = current_facility_products.new(account: Settings.accounts.product_default)
  end

  # POST /services
  def create
    @product = current_facility_products.new(create_params)
    @product.initial_order_status_id = OrderStatus.default_order_status.id

    if @product.save
      flash[:notice] = "#{@product.class.name} was successfully created."
      redirect_to([:manage, current_facility, @product])
    else
      render action: "new"
    end
  end

  # GET /facilities/alpha/(items|services|instruments)/1/edit
  def edit
  end

  # PUT /services/1
  def update
    respond_to do |format|
      if @product.update_attributes(update_params)
        flash[:notice] = "#{@product.class.name.capitalize} was successfully updated."
        format.html { redirect_to([:manage, current_facility, @product]) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /services/1
  def destroy
    if @product.destroy
      flash[:notice] = "#{@product.class.name} was successfully deleted"
    else
      flash[:error] = "There was a problem deleting the #{@product.class.name.to_lower}"
    end
    redirect_to [current_facility, plural_object_name]
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

  protected

  def translation_scope
    "controllers.products_common"
  end

  private

  def create_params
    params.require(:"#{singular_object_name}").permit(:name, :url_name, :contact_email, :description,
                                                      :facility_account_id, :account, :initial_order_status_id,
                                                      :requires_approval, :training_request_contacts,
                                                      :is_archived, :is_hidden, :order_notification_recipient,
                                                      :user_notes_field_mode, :user_notes_label, :show_details,
                                                      :schedule_id, :control_mechanism, :reserve_interval,
                                                      :min_reserve_mins, :max_reserve_mins, :min_cancel_hours,
                                                      :auto_cancel_mins, :lock_window, :cutoff_hours,
                                                      relay_attributes: [:ip, :port, :username, :password, :type, :instrument_id])
  end

  def update_params
    create_params
  end

  def assert_product_is_accessible!
    raise NUCore::PermissionDenied unless product_is_accessible?
  end

  def product_is_accessible?
    is_operator = session_user&.operator_of?(current_facility)
    !(@product.is_archived? || (@product.is_hidden? && !is_operator))
  end

  def current_facility_products
    product_class.where(facility: current_facility).alphabetized
  end

  def price_policy_available_for_product?
    groups = (acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect(&:id)
    @product.can_purchase?(groups)
  end

  # Dynamically get the proper object from the database based on the controller name
  def init_product
    @product = current_facility_products.find_by!(url_name: params[:"#{singular_object_name}_id"] || params[:id])
  end

  def product_class
    self.class.name.gsub(/Controller$/, "").singularize.constantize
  end
  helper_method :product_class

  # Get the object name to work off of. E.g. In ServicesController, this returns "services"
  def plural_object_name
    singular_object_name.pluralize
  end
  helper_method :plural_object_name

  def singular_object_name
    product_class.to_s.underscore
  end
  helper_method :singular_object_name

  def session_user_can_override_restrictions?(product)
    session_user.present? && session_user.can_override_restrictions?(product)
  end

end
