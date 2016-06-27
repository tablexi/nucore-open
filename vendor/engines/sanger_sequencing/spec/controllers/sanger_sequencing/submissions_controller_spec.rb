require "rails_helper"

RSpec.describe SangerSequencing::SubmissionsController do
  let(:facility) { FactoryGirl.create(:facility, sanger_sequencing_enabled: true) }
  let(:submission) { FactoryGirl.create(:sanger_sequencing_submission) }
  let(:user) { FactoryGirl.create(:user) }

  before do
    allow_any_instance_of(SangerSequencing::Submission).to receive(:facility).and_return(facility)
    allow_any_instance_of(SangerSequencing::Submission).to receive(:purchased?).and_return(false)
    allow_any_instance_of(SangerSequencing::Submission).to receive(:user).and_return(user)
  end

  describe "#edit" do
    describe "as the purchaser" do
      before { sign_in user }
      it "has access" do
        get :edit, id: submission.id
        expect(response).to be_success
      end
    end

    describe "as someone else" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in other_user }
      it "does not have access" do
        get :edit, id: submission.id
        expect(response.code).to eq("403")
      end
    end

    describe "as a global admin" do
      let(:admin) { FactoryGirl.create(:user, :administrator) }
      before { sign_in admin }
      it "does not have access" do
        get :edit, id: submission.id
        expect(response.code).to eq("403")
      end
    end
  end

  describe "#fetch_ids" do
    before { sign_in user }

    let(:data) { JSON.parse(response.body) }

    it "gets an array of ids" do
      get :fetch_ids, id: submission.id
      expect(data).to be_a(Array)
      expect(data.length).to eq(described_class::NEW_IDS_COUNT)
      expect(data).to all match(
        a_hash_including("id" => an_instance_of(Fixnum),
                         "customer_sample_id" => a_string_matching(/\A\d{4}\z/)),
      )
    end
  end
end
