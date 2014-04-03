class SurveyResponse

  attr_reader :params


  def initialize(params)
    @params = params
  end


  def save!
    od = OrderDetail.find params[:receiver_id]
    external_service = ExternalService.find params[:external_service_id]

    ExternalServiceReceiver.transaction do
      receiver = ExternalServiceReceiver.find_or_initialize_by_receiver_id_and_external_service_id od.id, external_service.id
      receiver.response_data = response_data
      receiver.save!
      od.merge!
      receiver
    end
  end


  def response_data
    show_url = params[:survey_url]
    # new survey services (i.e. IMSERC) provide the edit URL
    # old survey services (i.e. Surveyor) have the edit URL inferred
    edit_url = params[:survey_edit_url] || "#{show_url}/take"
    { show_url: show_url, edit_url: edit_url }.to_json
  end

end
