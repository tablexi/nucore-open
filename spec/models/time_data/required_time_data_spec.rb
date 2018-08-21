# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeData::RequiredTimeData, type: :model do
  let(:required_time_data) { described_class.new }

  describe "#problem_description_key" do
    subject(:problem_description_key) { required_time_data.problem_description_key }

    it { is_expected.to eq :missing_actuals }
  end
end
