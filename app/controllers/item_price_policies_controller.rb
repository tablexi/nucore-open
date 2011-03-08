require "date"
class ItemPricePoliciesController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_item

  load_and_authorize_resource

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /item_price_policies
  def index
    @current_price_policies = ItemPricePolicy.current(@item)
    @current_start_date     = @current_price_policies.first ? @current_price_policies.first.start_date : nil

    @next_price_policies    = ItemPricePolicy.next(@item)
    @next_start_date        = @next_price_policies.first ? @next_price_policies.first.start_date : nil

    @next_dates = ItemPricePolicy.next_dates(@item)
  end

  # GET /price_policies/new
  def new
    @price_groups   = current_facility.price_groups
    @start_date     = (Date.today + (@item.price_policies.first.nil? ? 0 : 1)).strftime("%m/%d/%Y")
    @price_policies = @price_groups.map{ |pg| ItemPricePolicy.new({:price_group_id => pg.id, :item_id => @item.id, :start_date => @start_date }) }
  end

  # GET /price_policies/1/edit
  def edit
    @price_groups = current_facility.price_groups
    @start_date = Date.strptime(params[:id], "%Y-%m-%d")
    raise ActiveRecord::RecordNotFound unless @start_date >= Date.today
    @price_policies = ItemPricePolicy.for_date(@item, @start_date)

    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0
  end

  # POST /price_policies
  def create
    @price_groups = current_facility.price_groups
    @start_date   = params[:start_date]
    @price_policies = @price_groups.map do |price_group|
      price_policy = ItemPricePolicy.new(params["item_price_policy#{price_group.id}"].reject {|k,v| k == 'restrict_purchase' })
      price_policy.price_group       = price_group
      price_policy.item              = @item
      price_policy.start_date        = Time.zone.parse(@start_date)
      price_policy.restrict_purchase = params["item_price_policy#{price_group.id}"]['restrict_purchase'] && params["item_price_policy#{price_group.id}"]['restrict_purchase'] == 'true' ? true : false
      price_policy
    end

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully created.'
          format.html { redirect_to facility_item_price_policies_url(current_facility, @item) }
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /price_policies/1
  def update
    @price_groups = current_facility.price_groups
    @start_date = Date.strptime(params[:id], "%Y-%m-%d")
    @price_policies = ItemPricePolicy.for_date(@item, @start_date)
    @price_policies.each { |price_policy|
      price_policy.attributes = params["item_price_policy#{price_policy.price_group.id}"].reject {|k,v| k == 'restrict_purchase' }
      price_policy.start_date = Time.zone.parse(params[:start_date])
      price_policy.restrict_purchase = params["item_price_policy#{price_policy.price_group.id}"]['restrict_purchase'] && params["item_price_policy#{price_policy.price_group.id}"]['restrict_purchase'] == 'true' ? true : false
    }

    respond_to do |format|
      if ActiveRecord::Base.transaction do
          raise ActiveRecord::Rollback unless @price_policies.all?(&:save)
          flash[:notice] = 'Price Rules were successfully updated.'
          format.html { redirect_to facility_item_price_policies_url(current_facility, @item) }
        end
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /price_policies/2010-01-01
  def destroy
    @price_groups   = current_facility.price_groups
    @start_date     = Date.strptime(params[:id], "%Y-%m-%d")
    raise ActiveRecord::RecordNotFound unless @start_date > Date.today
    @price_policies = ItemPricePolicy.for_date(@item, @start_date)
    raise ActiveRecord::RecordNotFound unless @price_policies.count > 0

    respond_to do |format|
      if ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @price_policies.all?(&:destroy)
        flash[:notice] = 'Price Rules were successfully removed'
        format.html { redirect_to facility_item_price_policies_url(current_facility, @item) }
        end
      else
        flash[:error] = 'An error was encountered while trying to remove the Price Rules'
        format.html { redirect_to facility_item_price_policies_url(current_facility, @item)  }
      end
    end
  end

  def init_item
    @item = current_facility.items.find_by_url_name!(params[:item_id])
  end
end
