class ServiceSurveysController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_service

  load_and_authorize_resource

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # PUT /facilities/1/services/1/surveys/xyz/activate
  def activate
    change_state(:activate)
  end

  # PUT /facilities/1/services/1/surveys/xyz/deactivate
  def deactivate
    change_state(:deactivate)
  end

  protected
  
  def change_state(state)
    @survey         = @service.surveys.find_by_access_code(params[:survey_code])
    @service_survey = @service.service_surveys.find_by_survey_id(@survey.id)
    
    case state
    when :activate
      @service_survey.try(:active!)
      flash[:notice] = "Survey activated"
    when :deactivate
      @service_survey.try(:inactive!)
      flash[:notice] = "Survey de-activated"
    end

    redirect_to(request.referer) and return
  end

  def init_service
    @service = current_facility.services.find_by_url_name!(params[:service_id])
  end
end
