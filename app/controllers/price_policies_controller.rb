class PricePoliciesController < ApplicationController

  include DateHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product
  before_action :init_price_policy, except: [:index, :new]
  before_action :build_price_policies!, only: [:create, :update]
  before_action :build_price_policies_for_edit!, only: :edit
  before_action :set_expire_date_from_params, only: [:create, :update]
  before_action :set_max_expire_date, only: [:edit, :update]

  load_and_authorize_resource instance_name: :price_policy

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies
  def index
    @current_price_policies = @product.price_policies.current_and_newest
    @current_start_date = @current_price_policies.first.try(:start_date)
    @past_price_policies_by_date = @product.past_price_policies_grouped_by_start_date
    @next_price_policies_by_date = @product.upcoming_price_policies_grouped_by_start_date
    render "price_policies/index"
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies/new
  def new
    @start_date = new_start_date
    @expire_date = set_max_expire_date
    @price_policies = PricePolicyBuilder.get_new_policies_based_on_most_recent(@product, @start_date)
    raise ActiveRecord::RecordNotFound if @price_policies.blank?
    render "price_policies/new"
  end

  # POST /facilities/:facility_id/{product_type}/:product_id/price_policies
  def create
    create_or_update(:new)
  end

  # PUT /facilities/:facility_id/{product_type}/:product_id/price_policies/:id
  def update
    create_or_update(:edit)
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies/:id/edit
  def edit
    @expire_date = @price_policies.map(&:expire_date).compact.first

    render "price_policies/edit"
  end

  # DELETE /facilities/:facility_id/{product_type}/:product_id/price_policies/:id
  def destroy
    return flash_remove_active_policy_warning_and_redirect if @start_date <= Date.today

    if PricePolicyUpdater.destroy_all_for_product!(@product, @start_date)
      flash[:notice] = text("destroy.success")
    else
      flash[:error] = text("destroy.failure")
    end
    redirect_to facility_product_price_policies_path
  end

  def translation_scope
    "controllers.price_policies"
  end

  private

  def active_policies?
    @product.price_policies.current.any?
  end

  def build_price_policies
    @price_policies ||= PricePolicyBuilder.get(@product, @start_date)
  end

  def build_price_policies!
    build_price_policies
    if @price_policies.blank?
      redirect_to facility_product_price_policies_path,
                  alert: text("errors.same_start_date")
    end
  end

  def build_price_policies_for_edit!
    build_price_policies
    raise ActiveRecord::RecordNotFound if @price_policies.blank?
  end

  def create_or_update(action)
    if update_policies_from_params!
      flash[:notice] = text("#{action}.success")
      redirect_to facility_product_price_policies_path
    else
      flash[:error] = text("errors.save")
      render "price_policies/#{action}"
    end
  end

  def facility_product_price_policies_path
    [current_facility, @product, PricePolicy]
  end

  # Override CanCan's find -- it won't properly search by zoned date
  def init_price_policy
    @start_date = start_date_from_params

    @price_policy = @product
                    .price_policies
                    .for_date(@start_date)
                    .first
  end

  def init_product
    id_param = params.except(:facility_id).keys.detect { |k| k.end_with?("_id") }
    clazz = id_param.sub(/_id\z/, "").camelize
    @product = current_facility.products(clazz)
                               .find_by!(url_name: params[id_param])
  end

  def new_start_date
    # If there are active policies, start tomorrow. If none, start today
    Date.today + (active_policies? ? 1 : 0)
  end

  def flash_remove_active_policy_warning_and_redirect
    flash[:error] =
      text("errors.remove_active_policy")
    redirect_to facility_product_price_policies_path
  end

  def set_expire_date_from_params
    @expire_date = params[:expire_date]
  end

  def set_max_expire_date
    @max_expire_date = PricePolicy.generate_expire_date(@start_date)
  end

  def start_date_from_params
    start_date = params[:id] || params[:start_date] || return
    format = start_date.include?("/") ? :usa : :ymd
    Date.strptime(start_date, I18n.t("date.formats.#{format}"))
  end

  def update_policies_from_params!
    PricePolicyUpdater.update_all!(
      @price_policies,
      parse_usa_date(params[:start_date]).beginning_of_day,
      parse_usa_date(@expire_date).end_of_day,
      params,
    )
  end

end
