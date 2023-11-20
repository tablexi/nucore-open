require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldTrainingSynchronizer do
  let!(:user) { create(:user, email: "Todd.Miller@oregonstate.edu") }
  let(:email) { user.email }
  let(:synchronizer) { described_class.new }
  let(:response) { File.expand_path("../../fixtures/scishield/success.json", __dir__) }
  let(:course_names) { ["Lab Safety Training for Lab Workers", "OSU Fire Extinguisher Course (in person)", "Hazardous Waste Awareness Training"] }
  let(:satus_code) { nil }
  let(:api_endpoint) { ResearchSafetyAdapters::ScishieldApiClient.new.api_endpoint(user.email) }

  before do
    stub_request(:get, api_endpoint)
      .to_return(
        status: status_code,
        body: File.new(response)
      )
  end

  context "when the API responses without error" do
    let(:status_code) { "200" }

    it "adds courses to database" do
      expect(ScishieldTraining.count).to eq 0
      synchronizer.synchronize
      expect(ScishieldTraining.count).to eq 3
      expect(ScishieldTraining.all.map(&:course_name)).to include(*course_names)
    end
  end

  context "when the API reponses with error" do
    let(:status_code) { 500 }

    it "does not add courses to database" do
      expect(ScishieldTraining.count).to eq 0
      synchronizer.synchronize
      expect(ScishieldTraining.count).to eq 0
    end
  end
end
