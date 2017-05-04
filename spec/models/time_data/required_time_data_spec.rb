require "rails_helper"

RSpec.describe TimeData::RequiredTimeData, type: :model do
  let(:required_time_data) { described_class.new }

  describe "#problem_description" do
    subject(:problem_description) { required_time_data.problem_description }

    it { is_expected.to eq required_time_data.text(:actual_usage_missing) }
  end
end
