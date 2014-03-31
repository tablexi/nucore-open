shared_context 'external service' do

  let(:external_service_passer) { create :external_service_passer, active: true }
  let(:external_service) { external_service_passer.external_service }
  let(:external_service_receiver) { create :external_service_receiver, external_service: external_service }

  let :params do {
    receiver_id: external_service_receiver.receiver.id,
    external_service_id: external_service.id,
    external_service_passer_id: external_service_passer.id,
    survey_url: 'http://survey.local/show',
    survey_edit_url: 'http://survey.local/edit'
  } end

end
