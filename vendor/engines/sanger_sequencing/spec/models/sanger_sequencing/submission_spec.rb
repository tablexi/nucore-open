# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Submission do
  it "can have a submission" do
    order_detail = FactoryBot.build(:order_detail)
    submission = described_class.create!(order_detail: order_detail)
    expect(submission.order_detail).to eq(order_detail)
  end

  describe "create_samples!" do
    let(:submission) { create(:sanger_sequencing_submission) }
    it "creates a series of samples" do
      expect { submission.create_samples!(3) }
        .to change(SangerSequencing::Sample, :count).by(3)
    end

    it "creates a series of samples from a string" do
      expect { submission.create_samples!("3") }
        .to change(SangerSequencing::Sample, :count).by(3)
    end

    it "creates a single sample if it receives nil" do
      expect { submission.create_samples!(nil) }
        .to change(SangerSequencing::Sample, :count).by(1)
    end

    it "creates a single sample if it receives a negative number" do
      expect { submission.create_samples!(-1) }
        .to change(SangerSequencing::Sample, :count).by(1)
    end

    it "creates a single sample if it receives a negative number as a string" do
      expect { submission.create_samples!("-12") }
        .to change(SangerSequencing::Sample, :count).by(1)
    end
  end
end
