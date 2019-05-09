# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Submission do
  let(:order_detail) { FactoryBot.build(:order_detail) }
  let(:subject) { described_class.create!(order_detail: order_detail) }

  it "can be created" do
    expect(subject.order_detail).to eq(order_detail)
  end

  describe "#create_prefilled_sample" do
    it "returns a sample" do
      expect(subject.create_prefilled_sample).to be_kind_of(SangerSequencing::Sample)
    end

    it "sets customer_sample_id to the id of the sample padded and limitedto 4 places" do
      sample = subject.create_prefilled_sample
      expect(sample.customer_sample_id).to eq(("%04d" % sample.id).last(4))
    end
  end
end
