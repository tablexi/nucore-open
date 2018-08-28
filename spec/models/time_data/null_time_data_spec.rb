# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeData::NullTimeData, type: :model do
  let(:null_time_data) { described_class.new }

  describe "#problem_description_key" do
    subject(:problem_description_key) { null_time_data.problem_description_key }

    it { is_expected.to be_blank }
  end
end
