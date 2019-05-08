# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Sample do
  it "belongs to a submission" do
    submission = SangerSequencing::Submission.create!
    sample = described_class.create!(submission: submission, customer_sample_id: "1234")
    expect(sample.submission).to eq(submission)
  end

  describe "#form_customer_sample_id" do
    let(:sample) { described_class.new.tap { |s| s.id = id } }
    subject(:customer_sample_id) { sample.form_customer_sample_id }

    describe "when I've set the customer_sample_id myself" do
      let(:id) { 123 }
      before { sample.customer_sample_id = "TESTING" }
      it { is_expected.to eq("TESTING") }
    end

    describe "when ID is nil (before being persisted)" do
      let(:id) { nil }

      it "returns a 4-digit number" do
        expect(subject.length).to eq 4
      end
    end

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
