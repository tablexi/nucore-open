require "rails_helper"

RSpec.describe SangerSequencing::Sample do
  it "belongs to a submission" do
    submission = SangerSequencing::Submission.create!
    sample = described_class.create!(submission: submission)
    expect(sample.submission).to eq(submission)
  end

  describe "#customer_sample_id" do
    describe "setting on creation" do
      let(:submission) { FactoryGirl.create(:sanger_sequencing_submission) }
      let(:sample) { described_class.create!(submission: submission) }

      it "is prepopulated" do
        expect(sample.reload[:customer_sample_id]).to be_present
          .and(be_a(String))
          .and(have(4).characters)
      end
    end

    describe "format" do
      let(:sample) { described_class.new.tap { |s| s.id = id } }
      subject(:customer_sample_id) { sample.customer_sample_id }

      describe "when the ID is large" do
        let(:id) { 121_234 }
        it { is_expected.to eq("1234") }
      end

      describe "when the ID is less than 4 characters" do
        let(:id) { 12 }
        it { is_expected.to eq("0012") }
      end

      describe "when the ID has a zero in the thousands" do
        let(:id) { 120_123 }
        it { is_expected.to eq("0123") }
      end
    end
  end
end
