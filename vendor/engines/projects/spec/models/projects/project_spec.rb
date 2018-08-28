# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::Project, type: :model do
  subject(:project) { build(:project) }

  context "validations" do
    it { is_expected.to validate_presence_of(:facility_id) }
    it { is_expected.to belong_to(:facility).with_foreign_key(:facility_id) }
    it { is_expected.to have_many(:order_details).inverse_of(:project) }

    it "enforces unique names per facility" do
      is_expected
        .to validate_uniqueness_of(:name)
        .case_insensitive
        .scoped_to(:facility_id)
    end
  end

  context "when its facility is destroyed" do
    subject(:project) { create(:project) }

    before { project.facility.destroy }

    it "is destroyed" do
      pending "Facilities cannot be destroyed"
      is_expected.to be_destroyed
    end
  end

  describe "#total_cost" do
    before do
      project.order_details.build(estimated_cost: nil, estimated_subsidy: nil)
      project.order_details.build(estimated_cost: 1.5, estimated_subsidy: 0.25)
      project.order_details.build(estimated_cost: 2.3, estimated_subsidy: 0, actual_cost: 3.24, actual_subsidy: 0.03)
    end

    it "finds the total" do
      expect(project.total_cost).to eq(4.46)
    end
  end
end
