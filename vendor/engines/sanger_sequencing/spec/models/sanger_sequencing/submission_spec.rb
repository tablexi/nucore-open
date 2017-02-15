require "rails_helper"

RSpec.describe SangerSequencing::Submission do
  it "can have a submission" do
    order_detail = FactoryGirl.build(:order_detail)
    submission = described_class.create!(order_detail: order_detail)
    expect(submission.order_detail).to eq(order_detail)
  end
end
