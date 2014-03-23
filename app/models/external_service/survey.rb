class Survey < UrlService

  attr_reader :service, :params


  def initialize(service, params)
    @service = service
    @params = params
  end


  def activate
    deactivate_current
    external_service_passer.update_attribute :active, true
  end


  def deactivate
    external_service_passer.update_attribute :active, false
  end


  def deactivate_current
    old_active = service.external_service_passers.find_by_active true
    old_active.update_attribute(:active, false) if old_active
  end


  def save!
    od = OrderDetail.find params[:receiver_id]
    external_service = ExternalService.find params[:external_service_id]

    ExternalServiceReceiver.create!(
      receiver: od,
      external_service: external_service,
      response_data: response_data
    )

    od.merge!
  end


  def response_data
    show_url = params[:survey_url]
    # new survey services (i.e. IMSERC) provide the edit URL
    # old survey services (i.e. Surveyor) have the edit URL inferred
    edit_url = params[:survey_edit_url] || "#{show_url}/take"
    { show_url: show_url, edit_url: edit_url }.to_json
  end


  def external_service_passer
    esp_id = params[:external_service_passer_id]
    @external_service_passer ||= service.external_service_passers.find(esp_id)
  end

end
