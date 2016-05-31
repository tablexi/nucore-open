require "rails_helper"

RSpec.describe SangerSequencing::Sample do
  it "belongs to a submission" do
    submission = SangerSequencing::Submission.create!
    sample = described_class.create!(submission: submission)
    expect(sample.submission).to eq(submission)
  end
end
