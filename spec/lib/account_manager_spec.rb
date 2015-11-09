require "rails_helper"

RSpec.describe AccountManager do

  describe ".creatable_account_types_for_facility" do
    subject(:account_types) { described_class.creatable_account_types_for_facility(facility) }

    context "is a single facility" do
      let(:facility) { create(:facility) }

      it { is_expected.to match_array(described_class.valid_account_types) }
    end

    context "is cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { is_expected.to all be_cross_facility }
    end
  end

end
