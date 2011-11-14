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
    @current_price_policies = model_class.current(@product)
    @current_start_date = @current_price_policies.first ? @current_price_policies.first.start_date : nil

    @next_price_policies = model_class.next(@product)
    @next_start_date = @next_price_policies.first ? @next_price_policies.first.start_date : nil

    @next_dates = model_class.next_dates(@product)
  end

  # GET /price_policies/new
  def new
    price_groups = current_facility.price_groups
    start_date     = Date.today + (@service.price_policies.active.empty? ? 0 : 1)
    @expire_date    = PricePolicy.generate_expire_date(start_date).strftime("%m/%d/%Y")
    @start_date=start_date.strftime("%m/%d/%Y")
    policy_class = model_class
    @price_policies = price_groups.map{ |pg| policy_class.new({:price_group_id => pg.id, :"#{@product_var}_id" => @product.id, :start_date => @start_date }) }
  end

  # POST /price_policies
  def create
    price_groups = current_facility.price_groups
    @start_date = params[:start_date]
    @expire_date   = params[:expire_date]
    price_groups.delete_if {|pg| !pg.can_purchase? @product }
    @price_policies = price_groups.map do |price_group|
      pp_param=params["#{@product_var}_price_policy#{price_group.id}"]
      price_policy = model_class.new(pp_param.reject {|k,v| k == 'restrict_purchase' })
      price_policy.price_group = price_group
      price_policy.send(:"#{@product_var}=", @product)
      #price_policy.service = @service
      price_policy.start_date = parse_usa_date(@start_date)
      price_policy.expire_date = parse_usa_date(@expire_date)
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
      price_policy
    end

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully created.'
          format.html { redirect_to method("facility_#{@product_var}_price_policies_url").call(current_facility, @product) }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  
  # GET /price_policies/1/edit
  def edit
    @start_date = start_date_from_params
    @price_policies = model_class.for_date(@product, @start_date)
    @price_policies.delete_if{|pp| pp.assigned_to_order? }
    raise ActiveRecord::RecordNotFound if @price_policies.blank?
    @expire_date=@price_policies.first.expire_date
  end


  private

  def init_product
    product_var=model_name.gsub('PricePolicy', '').downcase
    var=current_facility.method(product_var.pluralize).call.find_by_url_name!(params["#{product_var}_id".to_sym])
    instance_variable_set("@#{product_var}", var)
    @product = var
    @product_var = product_var
  end
  
  
  def model_name
    self.class.name.gsub('Controller', '').singularize
  end
  def model_class
    model_name.constantize
  end
  

  #
  # Override CanCan's find -- it won't properly search by zoned date
  def init_price_policy
    product_var="@#{model_name.gsub('PricePolicy', '').downcase}"
    instance_variable_set(
      "@#{model_name.underscore}",
      model_name.constantize.for_date(instance_variable_get(product_var), start_date_from_params).first
    )
  end


  def start_date_from_params
    start_date=params[:id] || params[:start_date]
    return unless start_date
    format=start_date.include?('/') ? "%m/%d/%Y" : "%Y-%m-%d"
    Date.strptime(start_date, format)
  end

end