require "rails_helper"

RSpec.describe Projects::Project, type: :model do
  subject(:project) { build(:project) }

  context "validations" do
    it { is_expected.to validate_presence_of(:facility_id) }
    it { is_expected.to belong_to(:facility).with_foreign_key(:facility_id) }

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
end
