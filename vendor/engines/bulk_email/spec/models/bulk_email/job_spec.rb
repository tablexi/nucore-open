require "rails_helper"

RSpec.describe BulkEmail::Job, type: :model do

  describe "string field validations" do
    subject(:bulk_email_job) { FactoryGirl.build(:bulk_email_job) }

    it { is_expected.to validate_presence_of(:sender) }
    it { is_expected.to validate_presence_of(:subject) }
  end

  describe "#recipients=" do
    subject(:bulk_email_job) do
      FactoryGirl.build(:bulk_email_job, recipients: recipients)
    end

    context "when set as a String" do
      context "that is a JSON Array" do
        let(:recipients) { '["a@example.com", "b@example.net"]' }

        it "accepts the String" do
          is_expected.to be_valid
          expect(bulk_email_job.recipients).to eq(recipients)
        end
      end

      context "that is not a JSON Array" do
        let(:recipients) { "non-json garbage" }

        it "is invalid" do
          is_expected.not_to be_valid
          expect(bulk_email_job.errors[:recipients])
            .to include("Must be an Array")
        end
      end
    end

    context "when set as an Array" do
      let(:recipients) { %w(a@example.com b@example.net) }

      it "serializes into a JSON String" do
        is_expected.to be_valid
        expect(bulk_email_job.recipients)
          .to eq '["a@example.com", "b@example.net"]'
      end
    end

    context "when set as a non-String and non-Array object" do
      let(:recipients) { { not_a_string: "and not an array" } }

      it "is invalid" do
        is_expected.not_to be_valid
        expect(bulk_email_job.errors[:recipients])
          .to include("Must be an Array")
      end
    end
  end

  describe "#search_criteria=" do
    subject(:bulk_email_job) do
      FactoryGirl.build(:bulk_email_job, search_criteria: search_criteria)
    end

    context "when set as a String" do
      context "that is a JSON Hash (object)" do
        let(:search_criteria) { '{ "a": "one", "b": "two" }' }

        it "accepts the String" do
          is_expected.to be_valid
          expect(bulk_email_job.search_criteria).to eq(search_criteria)
        end
      end

      context "that is not a JSON Hash (object)" do
        let(:search_criteria) { "non-json garbage" }

        it "is invalid" do
          is_expected.not_to be_valid
          expect(bulk_email_job.errors[:search_criteria])
            .to include("Must be a Hash")
        end
      end
    end

    context "when set as a Hash" do
      let(:search_criteria) { { a: "one", b: "two" } }

      it "serializes into a JSON String" do
        is_expected.to be_valid
        expect(bulk_email_job.search_criteria).to eq '{"a":"one","b":"two"}'
      end
    end

    context "when set as a non-String and non-Hash object" do
      let(:search_criteria) { %w(a b c) }

      it "is invalid" do
        is_expected.not_to be_valid
        expect(bulk_email_job.errors[:search_criteria])
          .to include("Must be a Hash")
      end
    end
  end
end
