# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrlService do

  let(:url_service) do
    described_class.create(
      location: "http://www.survey.com/survey1",
      default_url_options: { host: "defaulthost", port: nil },
    )
  end

  let(:service) { create :setup_service }
  let(:order) { create :setup_order, product: service }
  let(:order_detail) { create :order_detail, order: order, product: service, quantity: 3 }

  let(:facility) { order_detail.product.facility }
  let(:product) { order_detail.product }

  let(:query_hash) { Rack::Utils.parse_query(uri.query) }
  let(:uri) { URI(url_service.new_url(order_detail)) }

  it "uses the service's location as its base" do
    expect(uri.to_s).to start_with("http://www.survey.com/survey1?")
  end

  describe "with a request" do
    let(:request) { double(host_with_port: "realdomain:8080", fullpath: "/mysite", host: "realdomain", port: 8080, protocol: "https://") }
    let(:uri) { URI(url_service.new_url(order_detail, request)) }

    it "sets the correct receiver id" do
      expect(query_hash["receiver_id"]).to eq(order_detail.id.to_s)
    end

    it "sets the quantity" do
      expect(query_hash["quantity"]).to eq("3")
    end

    it "sets the order number" do
      expect(query_hash["order_number"]).to eq(order_detail.to_s)
    end

    it "sets the correct success url" do
      expect(query_hash["success_url"])
        .to eq("https://realdomain:8080/#{I18n.t('facilities_downcase')}/#{facility.url_name}/services/#{product.url_name}/surveys/#{url_service.id}/complete?receiver_id=#{order_detail.id}")
    end

    it "returns a blank referer" do
      expect(query_hash["referer"]).to eq("https://realdomain:8080/mysite")
    end
  end

  describe "without a request" do
    it "sets the correct success url" do
      expect(query_hash["success_url"])
        .to eq("http://defaulthost/#{I18n.t('facilities_downcase')}/#{facility.url_name}/services/#{product.url_name}/surveys/#{url_service.id}/complete?receiver_id=#{order_detail.id}")
    end

    it "returns a blank referer" do
      expect(query_hash["referer"]).to be_blank
    end
  end
end
