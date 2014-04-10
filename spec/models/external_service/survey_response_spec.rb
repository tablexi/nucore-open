require 'spec_helper'

describe SurveyResponse do
  include_context 'external service'

  let :deserialized_response_data do {
    show_url: params[:survey_url],
    edit_url: params[:survey_edit_url]
  } end


  subject(:survey_response) { described_class.new params }


  it 'has a params accessor' do
    expect(survey_response.params).to eq params
  end

  it 'gives a String of URL JSON' do
    expect(survey_response.response_data).to eq deserialized_response_data.to_json
  end

  it 'provides a Surveyor edit URL if an edit URL is not given' do
    params[:survey_edit_url] = nil
    deserialized_response_data[:edit_url] = "#{params[:survey_url]}/take"
    expect(survey_response.response_data).to eq deserialized_response_data.to_json
  end

  it 'creates an external service receiver' do
    expect { survey_response.save! }.to change{ ExternalServiceReceiver.count }.by 1
    esr = ExternalServiceReceiver.last
    expect(esr.receiver).to eq external_service_receiver.receiver
    expect(esr.external_service).to eq external_service
    expect(esr.response_data).to eq deserialized_response_data.to_json
  end

  it 'merges the order detail' do
    od = external_service_receiver.receiver
    expect(OrderDetail).to receive(:find).and_return od
    expect(od).to receive :merge!
    survey_response.save!
  end

  it 'reuses existing ExternalServiceReceivers' do
    expect {
      survey_response.save!
      survey_response.save!
    }.to change{ ExternalServiceReceiver.count }.by 1
  end

  it 'updates the response_data if it has changed' do
    new_survey_url = 'http://yippee.kid'

    expect {
      receiver = survey_response.save!
      expect(receiver.show_url).to_not eq new_survey_url
      params[:survey_url] = new_survey_url
      receiver = described_class.new(params).save!
      expect(receiver.show_url).to eq new_survey_url
    }.to change{ ExternalServiceReceiver.count }.by 1
  end

  it 'stores the survey_id as the external_id' do
    receiver = survey_response.save!
    expect(receiver.external_id).to eq params[:survey_id]
  end

  describe 'quantity updates' do
    let(:order_detail) { external_service_receiver.receiver }

    it 'updates the receiver quantity' do
      params[:quantity] += 3
      expect_any_instance_of(OrderDetail).to receive(:update_quantity).with(params[:quantity]).and_call_original
      receiver = survey_response.save!
      expect(receiver.receiver.quantity).to eq params[:quantity]
    end

    it 'does not change the quantity if no quantity is given' do
      params[:quantity] = nil
      quantity = order_detail.quantity
      expect_any_instance_of(OrderDetail).to_not receive :update_quantity
      receiver = survey_response.save!
      expect(receiver.receiver.quantity).to eq quantity
    end
  end

end
