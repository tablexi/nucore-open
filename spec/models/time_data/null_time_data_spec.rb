require "rails_helper"

RSpec.describe TimeData::NullTimeData, type: :model do
  let(:null_time_data) { described_class.new }

  describe "#problem_description" do
    subject(:problem_description) { null_time_data.problem_description }

    it { is_expected.to be_blank }
  end
end
