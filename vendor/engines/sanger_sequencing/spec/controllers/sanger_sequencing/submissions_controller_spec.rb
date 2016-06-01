require "rails_helper"

RSpec.describe SangerSequencing::SubmissionsController do
  let(:submission) { FactoryGirl.create(:sanger_sequencing_submission) }

  describe "#fetch_ids" do
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
