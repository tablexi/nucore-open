# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalServiceReceiver do
  let(:parsed_response_data) do
    { show_url: "http://survey.test.local/show", edit_url: "http://survey.test.local/edit" }
  end

  subject(:receiver) do
    described_class.new response_data: parsed_response_data.to_json
  end

  it { is_expected.to have_db_column :receiver_type }
  it { is_expected.to validate_presence_of :receiver_id }
  it { is_expected.to validate_presence_of :external_service_id }
  it { is_expected.to validate_presence_of :response_data }

  it "responds to keys in the response data" do
    parsed_response_data.each do |key, _|
      expect(receiver).to respond_to key
    end
  end

  it "returns the values of keys in the response data when the keys are called as methods" do
    parsed_response_data.each do |key, value|
      expect(receiver.send(key)).to eq value
    end
  end

  describe "error handling" do
    it "does not raise an error when response_data is nil" do
      receiver.response_data = nil
      expect(receiver).to_not respond_to :foo
    end

    it "does not raise an error when response_data is not JSON" do
      receiver.response_data = "a random string"
      expect(receiver).to_not respond_to :foo
    end
  end
end
