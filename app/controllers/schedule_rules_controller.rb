class ScheduleRulesController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product

  load_and_authorize_resource

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/alias/instruments/3/schedule_rules
  # GET /facilities/alias/instruments/3/schedule_rules.js?_=1279582221312&start=369205200&end=369810000
  def index
    @start_at       = Time.zone.at(params[:start].to_i)
    @end_at         = Time.zone.at(params[:end].to_i)
    @schedule_rules = @product.schedule_rules

    respond_to do |format|
      format.html # index.html.haml
      format.js do
        render json: ScheduleRuleCalendarPresenter.to_json(@schedule_rules)
      end
    end
  end

  # GET /schedule_rules/new
  def new
    @schedule_rule = @product.schedule_rules.build(
      start_hour: 9,
      start_min: 0,
      end_hour: 17,
      end_min: 0,
    )
  end

  # GET /schedule_rules/1/edit
  def edit
    @schedule_rule  = @product.schedule_rules.find(params[:id])
  end

  # POST /schedule_rules
  def create
    @schedule_rule  = @product.schedule_rules.new(params[:schedule_rule])

    if @schedule_rule.save
      flash[:notice] = text("create")
      redirect_to action: :index
    else
      render action: "new"
    end
  end

  # PUT /schedule_rules/1
  def update
    @schedule_rule = @product.schedule_rules.find(params[:id])

    # if there are no boxes checked, remove them all
    params[:schedule_rule][:product_access_group_ids] ||= []

    if @schedule_rule.update_attributes(params[:schedule_rule])
      flash[:notice] = text("update")
      redirect_to action: :index
    else
      render action: "edit"
    end
  end

  # DELETE /schedule_rules/1
  def destroy
    @schedule_rule = @product.schedule_rules.find(params[:id])
    @schedule_rule.destroy

    flash[:notice] = text("destroy")
    redirect_to action: :index
  end

  private

  def init_product
    @product = current_facility.products.find_by!(url_name: product_id)
  end

  def product_id
    params[product_key]
  end

  def product_key
    params.except(:facility_id).keys.find { |k| k.end_with?("_id") }
  end

end
