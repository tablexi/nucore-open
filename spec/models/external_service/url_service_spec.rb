require 'spec_helper'

describe UrlService do

  let(:urls) do
    { show_url: 'http://show.survey.com', edit_url: 'http://edit.survey.com' }
  end

  let :receiver do
    double external_service_receiver: double(response_data: urls.to_json)
  end

  subject(:url_service) { described_class.create location: 'http://www.survey.com' }


  it { should respond_to :request }

  it { should respond_to :request= }

  it 'gives the edit url' do
    expect(url_service.edit_url(receiver)).to eq urls[:edit_url]
  end

  it 'gives the show url' do
    expect(url_service.show_url(receiver)).to eq urls[:show_url]
  end


  describe 'the URL for a new entry at the external service' do
    let(:service) { create :setup_service }
    let(:order) { create :setup_order, product: service }
    let(:order_detail) { create :order_detail, order: order, product: service }
    let :url_components do {
        :facility_id => order_detail.product.facility.url_name,
        :service_id => order_detail.product.url_name,
        :external_service_id => url_service.id,
        :receiver_id => order_detail.id
    } end

    it 'uses the default host, port, and protocol if there is no request' do
      expect(url_service.request).to be_nil
      url_service.default_url_options[:host] = 'localhost'
      complete_survey_url = url_service.complete_survey_url url_components
      url = "#{url_service.location}?#{{ success_url: complete_survey_url}.to_query}"
      expect(url_service.new_url(order_detail)).to eq url
    end

    it 'uses the host, port, and protocol of the request' do
      host_params = { host: 'localhost.test', port: 8080, protocol: 'https' }
      url_service.request = double host_params
      complete_survey_url = url_service.complete_survey_url url_components.merge(host_params)
      url = "#{url_service.location}?#{{ success_url: complete_survey_url}.to_query}"
      expect(url_service.new_url(order_detail)).to eq url
    end
  end

end
