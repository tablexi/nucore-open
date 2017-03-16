class ScheduleRulesController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product
  before_action :init_schedule_rule, only: [:edit, :update, :destroy]

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

  # POST /schedule_rules
  def create
    @schedule_rule = @product.schedule_rules.new(schedule_rule_params)

    if @schedule_rule.save
      flash[:notice] = text("create")
      redirect_to action: :index
    else
      render action: "new"
    end
  end

  # GET /schedule_rules/1/edit
  def edit
  end

  # PUT /schedule_rules/1
  def update
    # if there are no boxes checked, the empty array will mark the
    # existing ones for destruction
    params[:schedule_rule][:product_access_group_ids] ||= []

    if @schedule_rule.update_attributes(schedule_rule_params)
      flash[:notice] = text("update")
      redirect_to action: :index
    else
      render action: "edit"
    end
  end

  # DELETE /schedule_rules/1
  def destroy
    @schedule_rule.destroy

    flash[:notice] = text("destroy")
    redirect_to action: :index
  end

  private

  def schedule_rule_params
    params.require(:schedule_rule).permit(:discount_percent, :start_hour, :start_min, :end_hour, :end_min,
                                          :on_sun, :on_mon, :on_tue, :on_wed, :on_thu, :on_fri, :on_sat,
                                          product_access_group_ids: [])
  end

  def init_product
    @product = current_facility.products.find_by!(url_name: product_id)
  end

  def init_schedule_rule
    @schedule_rule = @product.schedule_rules.find(params[:id])
  end

  def product_id
    params[product_key]
  end

  def product_key
    params.except(:facility_id).keys.find { |k| k.end_with?("_id") }
  end

end
