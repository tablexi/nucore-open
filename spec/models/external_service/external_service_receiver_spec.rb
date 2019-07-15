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

  describe "#show_url" do
    it "returns the show url from the response_data attribute" do
      expect(subject.show_url).to eq "http://survey.test.local/show"
    end
  end

  describe "#edit_url" do
    it "returns the edit url from the response_data attribute" do
      expect(subject.edit_url).to eq "http://survey.test.local/edit"
    end
  end
end
