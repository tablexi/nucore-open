class PricePoliciesController < ApplicationController
  include DateHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_product
  before_filter :init_price_policy, :except => [ :index, :new ]

  load_and_authorize_resource

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  def index
    @current_price_policies = @product.price_policies.current
    @current_start_date = @current_price_policies.first ? @current_price_policies.first.start_date : nil
    @past_price_policies_by_date = @product.past_price_policies_grouped_by_start_date
    @next_price_policies_by_date = @product.upcoming_price_policies_grouped_by_start_date
    render 'price_policies/index'
  end

  # GET /price_policies/new
  def new
    # If there are active policies, start tomorrow. If none, start today
    @start_date     = Date.today + (@product.price_policies.current.empty? ? 0 : 1)

    @expire_date    = PricePolicy.generate_expire_date(@start_date)
    @max_expire_date = @expire_date

    build_price_policies!

    # Base the new policies off the most recent version
    new_price_policy_list = []
    @price_policies.each do |pp|
      existing_pp = @product.price_policies.where(:price_group_id => pp.price_group.id).order(:expire_date).last
      new_price_policy_list << (existing_pp ? existing_pp.dup : pp)
    end
    # If it's all new policies (i.e. nothing changed in the list), make the default can_purchase true
    new_price_policy_list.each { |pp| pp.can_purchase = true } if @price_policies == new_price_policy_list

    @price_policies = new_price_policy_list

    render 'price_policies/new'
  end

  # POST /facilities/:facility_id/{product_type}/:product_id/price_policies
  def create
    @start_date = start_date_from_params
    @expire_date = params[:expire_date]

    build_price_policies!

    if update_policies_from_params!
      flash[:notice] = I18n.t("controllers.price_policies.create.success")
      redirect_to facility_product_price_policies_path
    else
      flash[:error] = I18n.t("controllers.price_policies.errors.save")
      render "price_policies/new"
    end
  end

  # GET /price_policies/1/edit
  def edit
    @start_date = start_date_from_params

    build_price_policies!

    @expire_date=@price_policies.map(&:expire_date).compact.first
    @max_expire_date = PricePolicy.generate_expire_date(@start_date)

    render 'price_policies/edit'
  end

  # PUT /facilities/:facility_id/{product_type}/:product_id/price_policies/:id
  def update
    @start_date = start_date_from_params

    build_price_policies!

    @expire_date = params[:expire_date]
    @max_expire_date = PricePolicy.generate_expire_date(@start_date)

    if update_policies_from_params!
      flash[:notice] = I18n.t("controllers.price_policies.update.success")
      redirect_to facility_product_price_policies_path
    else
      flash[:error] = I18n.t("controllers.price_policies.errors.save")
      render "price_policies/edit"
    end
  end

  # DELETE /price_policies/2010-01-01
  def destroy
    @start_date     = start_date_from_params
    unless @start_date > Date.today
      # force the user to really think about what they're doing, but tell them how to do it if they really want.
      flash[:error] = I18n.t('controllers.price_policies.errors.remove_active_policy')
      return redirect_to facility_product_price_policies_path
    end

    @price_policies = @product.price_policies.for_date(@start_date)
    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0

    respond_to do |format|
      if ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @price_policies.all?(&:destroy)
        flash[:notice] = 'Price Rules were successfully removed'
        format.html { redirect_to facility_product_price_policies_path }
        end
      else
        flash[:error] = 'An error was encountered while trying to remove the Price Rules'
        format.html { redirect_to facility_product_price_policies_path  }
      end
    end
  end

  private

  def facility_product_price_policies_path
    method("facility_#{@product_var}_price_policies_path").call(current_facility, @product)
  end

  def init_product
    product_var=model_name.gsub('PricePolicy', '').downcase
    var=current_facility.method(product_var.pluralize).call.find_by_url_name!(params["#{product_var}_id".to_sym])
    instance_variable_set("@#{product_var}", var)
    @product = var
    @product_var = product_var
  end

  def build_price_policies!
    @price_policies = PricePolicyBuilder.get(@product, @start_date)
    raise ActiveRecord::RecordNotFound if @price_policies.blank?
  end

  def update_policies_from_params!
    PricePolicyUpdater.update_all!(
      @price_policies,
      parse_usa_date(params[:start_date]).beginning_of_day,
      parse_usa_date(@expire_date).end_of_day,
      params,
    )
  end

  def model_name
    self.class.name.gsub('Controller', '').singularize
  end

  #
  # Override CanCan's find -- it won't properly search by zoned date
  def init_price_policy
    product_var="@#{model_name.gsub('PricePolicy', '').downcase}"

    instance_variable_set(
      "@#{model_name.underscore}",
      instance_variable_get(product_var).price_policies.for_date(start_date_from_params).first
    )
  end


  def start_date_from_params
    start_date=params[:id] || params[:start_date]
    return unless start_date
    format=start_date.include?('/') ? "%m/%d/%Y" : "%Y-%m-%d"
    Date.strptime(start_date, format)
  end

end
