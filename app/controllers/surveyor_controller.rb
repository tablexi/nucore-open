module SurveyorControllerCustomMethods
  def self.included(base)
    # TODO security and check_acting_as needs to be added
    base.send :before_filter, :init_current_facility, :only => [:preview, :show_admin]
    base.send :before_filter, :authenticate_user!
    base.send :before_filter, :init_order, :only => [:create, :edit, :show, :new]

    base.send :load_and_authorize_resource, :class => ServiceSurvey, :only => [:preview, :show_admin]

    base.send :layout, 'application' # use nucore layout
    base.send :customer_tab, :edit, :show
    base.send :admin_tab, :preview, :show_admin
  end

  def init_order
    begin
      @order = acting_user.orders.find(params[:order_id])
    rescue Exception => e
      if current_user.administrator?
        # allow admin to find any order
        @order = Order.find(params[:order_id])
      else
        raise e
      end
    end
  end

  # Actions
  def new
    super
    # @title = "You can take these surveys"
  end
  
  # GET /orders/1/details/3/survey/123abc
  def create
    # start survey, and attach it to the specified order and order detail
    # @order initialized in before filter
    @detail       = @order.order_details.find(params[:od_id])
    @survey       = Survey.find_by_access_code(params[:survey_code])
    @response_set = @survey.response_sets.create

    if (@survey && @response_set)
      # attach response_set to order detail
      @detail.response_set!(@response_set)
      flash[:notice] = t('surveyor.survey_started_success')
      redirect_to(edit_order_survey_path(@order, @detail, @survey.access_code, @response_set.access_code))
    else
      flash[:notice] = t('surveyor.Unable_to_find_that_survey')
      redirect_to(surveyor_index)
    end
  end

  # GET /orders/1/details/3/survey/123abc/xyyzz
  def show
    ## copied from surveyor_controller_methods in order to override view without render twice errors
    @response_set = ResponseSet.find_by_access_code!(params[:response_set_code], :include => {:responses => [:question, :answer]})  
    @survey       = @response_set.survey
    @service      = ServiceSurvey.find_by_survey_id(@survey.id).service
    @facility     = @service.facility
    @order_detail = @order.order_details.find(params[:od_id])

    surveyor_view_path = view_paths[view_paths.index{|p| p.to_s.match(/\/surveyor/)}]
    @rendered     = render_to_string "#{surveyor_view_path}/surveyor/show.html.haml"

    @active_tab = 'orders'
  end
  
  # GET '/facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/surveys/:survey_code/:response_set_code.:format'
  def show_admin
    ## copied from surveyor_controller_methods in order to override view without render twice errors
    @response_set = ResponseSet.find_by_access_code!(params[:response_set_code], :include => {:responses => [:question, :answer]})  
    @survey       = @response_set.survey
    @service      = ServiceSurvey.find_by_survey_id(@survey.id).service
    @order        = current_facility.orders.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])

    surveyor_view_path = view_paths[view_paths.index{|p| p.to_s.match(/\/surveyor/)}]
    @rendered     = render_to_string "#{surveyor_view_path}/surveyor/show.html.haml"

    @active_tab = 'admin_orders'
    respond_to do |format|
      format.html {render :action => 'show_admin'}
      format.csv {
        send_data(@response_set.to_csv, :type => 'text/csv; charset=utf-8; header=present',:filename => "#{@response_set.updated_at.strftime('%Y-%m-%d')}_#{@response_set.access_code}.csv")
      }
    end
  end

  # GET /orders/1/details/3/survey/123abc/xyyzz/edit
  def edit
    super
    @active_tab = 'orders'
    @service    = ServiceSurvey.find_by_survey_id(@survey.id).service
    @facility   = @service.facility
    
    surveyor_view_path = view_paths[view_paths.index{|p| p.to_s.match(/\/surveyor/)}]
    @rendered   = render_to_string "#{surveyor_view_path}/surveyor/edit.html.haml"
  end

  # PUT /facility-url/surveys/123abc/xxyyzz
  def update
    super
  end

  # GET /facilities/bi-test1/services/bitfo-service/surveys/test_survey/preview
  def preview
    @service      = Service.find_by_url_name(params[:service_id])
    @survey       = @service.surveys.find_by_access_code(params[:survey_code])
    # find or create the special preview response set
    @through      = @service.service_surveys.find_by_survey_id(@survey.id)
    @response_set = @through.find_or_create_preview_response_set
    
    @active_tab = 'admin_products'
    surveyor_view_path = view_paths[view_paths.index{|p| p.to_s.match(/\/surveyor/)}]
    @rendered   = render_to_string "#{surveyor_view_path}/surveyor/show.html.haml"
    render(:action => 'preview_admin')
  end

  # Paths
  def surveyor_index
    # most of the above actions redirect to this method
    super # available_surveys_path
  end

  def surveyor_finish
    # the update action redirects to this method if given params[:finish]
    # find response set, and related order detail + order
    @response_set  = ResponseSet.find_by_access_code(params[:response_set_code])
    @order_detail  = OrderDetail.find_by_response_set_id(@response_set.id)
    @order         = @order_detail.try(:order)
    
    if @order
      # redirect to order show
      return order_path(@order)
    else
      # find service associated with this survey; redirect to manage service path
      @ss       = ServiceSurvey.find_by_preview_code(@response_set.access_code)
      @service  = @ss.service
      return manage_facility_service_path(@service.facility, @service)
    end
    # super # available_surveys_path
  end
end

class SurveyorController < ApplicationController
  include Surveyor::SurveyorControllerMethods
  include SurveyorControllerCustomMethods
end
