require "rails_helper"

RSpec.describe UrlService do

  subject(:url_service) { described_class.create location: "http://www.survey.com" }

  let(:service) { create :setup_service }
  let(:order) { create :setup_order, product: service }
  let(:order_detail) { create :order_detail, order: order, product: service }

  let(:host_params) do
    {
      host: "localhost.test",
      port: 8080,
      protocol: "https",
    }
  end

  let :url_components do
    {
      facility_id: order_detail.product.facility.url_name,
      service_id: order_detail.product.url_name,
      external_service_id: url_service.id,
      receiver_id: order_detail.id,
    }
  end

  it "uses the default host, port, and protocol if there is no request" do
    url_service.default_url_options[:host] = "localhost"
    complete_survey_url = url_service.complete_survey_url url_components
    url = "#{url_service.location}?#{{ success_url: complete_survey_url, referer: nil, receiver_id: order_detail.id }.to_query}"
    expect(url_service.new_url(order_detail)).to eq url
  end

  it "uses the host, port, and protocol of the request" do
    complete_survey_url = url_service.complete_survey_url url_components.merge(host_params)
    host_params[:host_with_port] = "#{host_params[:host]}:#{host_params[:port]}"
    host_params[:fullpath] = "/path/to/somewhere"
    referer_url = "#{host_params[:protocol]}#{host_params[:host_with_port]}#{host_params[:fullpath]}"
    url = "#{url_service.location}?#{{ success_url: complete_survey_url, referer: referer_url, receiver_id: order_detail.id }.to_query}"
    expect(url_service.new_url(order_detail, double(host_params))).to eq url
  end

end
