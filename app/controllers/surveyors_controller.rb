class SurveyorsController < ApplicationController
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


  # PUT /facilities/1/services/1/surveys/2/activate
  def activate
    change_state(:activate)
  end


  # PUT /facilities/1/services/1/surveys/2/deactivate
  def deactivate
    change_state(:deactivate)
  end


  def complete
    begin
      ExternalServiceReceiver.create!(
          :receiver => OrderDetail.find(params[:receiver_id].to_i),
          :external_service => Surveyor.find(params[:external_service_id].to_i),
          :response_data => params[:survey_url]
      )
    rescue => e
      Rails.logger.error("Could not save external surveyor response! #{e.message}\n#{e.backtrace.join("\n")}")
    end

    redirect_to params[:referer]
  end


  private
  
  def change_state(state)
    @esp=@service.external_service_passers.find_by_id(params[:external_service_passer_id].to_i)
    activate=state == :activate

    if activate
      old_active=@service.external_service_passers.find_by_active(true)
      old_active.update_attribute(:active, false) if old_active
    end

    @esp.update_attribute(:active, activate)
    flash[:notice] = activate ? "Survey activated" : "Survey de-activated"        
    redirect_to(request.referer) and return
  end

  def init_service
    @service = current_facility.services.find_by_url_name!(params[:service_id])
  end
end
