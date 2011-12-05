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

    @next_dates = model_class.next_dates(@product).sort
  end

  # GET /price_policies/new
  def new
    price_groups = current_facility.price_groups
    start_date     = Date.today + (@product.price_policies.active.empty? ? 0 : 1)
    @expire_date    = PricePolicy.generate_expire_date(start_date).strftime("%m/%d/%Y")
    @max_expire_date = @expire_date
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
    
    @interval = params[:interval].to_i if params[:interval]
    
    @price_policies = price_groups.map do |price_group|
      pp_param=params["#{@product_var}_price_policy#{price_group.id}"]
      price_policy = model_class.new(pp_param.reject {|k,v| k == 'restrict_purchase' })
      price_policy.price_group = price_group
      # price_policy.service = @service
      price_policy.send(:"#{@product_var}=", @product)
      price_policy.start_date = parse_usa_date(@start_date).beginning_of_day
      price_policy.expire_date = parse_usa_date(@expire_date).end_of_day
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
      
      price_policy.usage_mins        = @interval if price_policy.respond_to?(:usage_mins=) and @interval
      price_policy.reservation_mins  = @interval if price_policy.respond_to?(:reservation_mins=) and @interval
      price_policy.overage_mins      = @interval if price_policy.respond_to?(:overage_mins=) and @interval
      
      price_policy
    end
    
    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully created.'
          format.html { redirect_to facility_product_price_policies_path }
        end
      else
        flash[:error] = "There was an error saving the policy"
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
    include_newer_price_groups    
    @max_expire_date = PricePolicy.generate_expire_date(@price_policies.first.start_date).strftime("%m/%d/%Y")
  end

  # PUT /price_policies/1
  def update
    @start_date = start_date_from_params
    @expire_date    = params[:expire_date]
    @price_policies = model_class.for_date(@product, @start_date)
    @interval = params[:interval].to_i if params[:interval]
    
    include_newer_price_groups
    
    @price_policies.each { |price_policy|
      pp_param=params["#{@product_var}_price_policy#{price_policy.price_group.id}"]
      next unless pp_param
      price_policy.attributes = pp_param.reject {|k,v| k == 'restrict_purchase' }
      price_policy.start_date = parse_usa_date(params[:start_date]).beginning_of_day
      price_policy.expire_date = parse_usa_date(@expire_date).end_of_day unless @expire_date.blank?
      
      price_policy.usage_mins        = @interval if price_policy.respond_to?(:usage_mins=) and @interval
      price_policy.reservation_mins  = @interval if price_policy.respond_to?(:reservation_mins=) and @interval
      price_policy.overage_mins      = @interval if price_policy.respond_to?(:overage_mins=) and @interval
      
      price_policy.restrict_purchase = pp_param['restrict_purchase'] && pp_param['restrict_purchase'] == 'true' ? true : false
    }

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully updated.'
          format.html { redirect_to facility_product_price_policies_path }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  # DELETE /price_policies/2010-01-01
  def destroy
    @start_date     = start_date_from_params

    unless @start_date > Date.today
      # force the user to really think about what they're doing, but tell them how to do it if they really want.
      flash[:notice]="Sorry, but you cannot remove an active price policy.<br/>If you really want to do so move the start date to the future and try again."
      return redirect_to facility_product_price_policies_path
    end

    @price_policies = model_class.for_date(@product, @start_date)
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
  
  # if a new price group has been added since the price policy was set up, we want to be able to add a price for it
  # otherwise you would have to create a brand new rule
  def include_newer_price_groups
    current_price_groups = @price_policies.map { |pp| pp.price_group }
    current_facility.price_groups.each do |group|
      if !current_price_groups.include?(group) and group.can_purchase?(@product)
        @price_policies << model_class.new({:price_group_id => group.id, :"#{@product_var}_id" => @product.id, :start_date => @start_date })
      end
    end
  end

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