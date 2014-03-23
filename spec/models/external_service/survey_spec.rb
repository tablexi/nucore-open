require 'spec_helper'

describe Survey do

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

  let :deserialized_response_data do {
    show_url: params[:survey_url],
    edit_url: params[:survey_edit_url]
  } end


  subject(:survey) { described_class.new external_service_passer.passer, params }


  it 'has a service accessor' do
    expect(survey.service).to eq external_service_passer.passer
  end

  it 'has a params accessor' do
    expect(survey.params).to eq params
  end

  it 'sets active to false on the currently active survey' do
    expect(external_service_passer).to be_active
    survey.deactivate_current
    expect(external_service_passer.reload).to_not be_active
  end

  it 'finds the external service passer' do
    expect(survey.external_service_passer).to eq external_service_passer
  end

  it 'makes the external service passer active' do
    external_service_passer.update_attribute :active, false
    expect(survey).to receive :deactivate_current
    survey.activate
    expect(external_service_passer.reload).to be_active
  end

  it 'makes the external service passer inactive' do
    survey.deactivate
    expect(external_service_passer.reload).to_not be_active
  end

  it 'gives a String of URL JSON' do
    expect(survey.response_data).to eq deserialized_response_data.to_json
  end

  it 'provides a Surveyor edit URL if an edit URL is not given' do
    params[:survey_edit_url] = nil
    deserialized_response_data[:edit_url] = "#{params[:survey_url]}/take"
    expect(survey.response_data).to eq deserialized_response_data.to_json
  end

  it 'creates an external service receiver' do
    expect(survey).to_not be_new_record
    expect { survey.save! }.to change{ ExternalServiceReceiver.count }.by 1
    esr = ExternalServiceReceiver.last
    expect(esr.receiver).to eq external_service_receiver.receiver
    expect(esr.external_service).to eq external_service
    expect(esr.response_data).to eq deserialized_response_data.to_json
  end

  it 'merges the order detail' do
    od = external_service_receiver.receiver
    expect(OrderDetail).to receive(:find).and_return od
    expect(od).to receive :merge!
    survey.save!
  end

end
