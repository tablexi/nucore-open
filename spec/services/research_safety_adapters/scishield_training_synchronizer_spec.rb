require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldTrainingSynchronizer do
  let!(:user) { create(:user, email: "Todd.Miller@oregonstate.edu") }
  let(:email) { user.email }
  let(:synchronizer) { described_class.new }
  let(:response) { File.expand_path("../../fixtures/scishield/success.json", __dir__) }
  let(:course_names) { ["Lab Safety Training for Lab Workers", "OSU Fire Extinguisher Course (in person)", "Hazardous Waste Awareness Training"] }
  let(:satus_code) { nil }

  before do
    stub_request(:get, "https://test-university.scishield.com/jsonapi/raft_training_record/raft_training_record?filter%5Bstatus%5D=1&filter%5Buser%5D%5Bcondition%5D%5Boperator%5D==&filter%5Buser%5D%5Bcondition%5D%5Bpath%5D=user_id.mail&filter%5Buser%5D%5Bcondition%5D%5Bvalue%5D=#{email}&include=course_id")
      .with(
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "UsersJwt ",
          "Host" => "test-university.scishield.com",
          "User-Agent" => "Ruby",
        })
      .to_return(status: status_code, body: File.new(response), headers: {})
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
