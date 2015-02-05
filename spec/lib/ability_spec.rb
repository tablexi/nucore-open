require "spec_helper"

describe Ability do
  subject(:ability) { Ability.new(user, price_group, stub_controller) }
  let(:facility) { create(:facility) }
  let(:stub_controller) { OpenStruct.new }

  shared_examples_for "it can manage price group members" do
    it "can manage its members" do
      expect(ability.can?(:manage_members, price_group)).to be true
    end
  end

  shared_examples_for "it cannot manage price group members" do
    it "can manage its members" do
      expect(ability.can?(:manage_members, price_group)).to be false
    end
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:price_group) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:price_group) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:price_group) { create(:price_group, :cancer_center) }

          it_behaves_like "it can manage price group members"
        end
      end
    end
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: facility) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:price_group) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:price_group) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:price_group) { create(:price_group, :cancer_center) }

          it_behaves_like "it cannot manage price group members"
        end
      end
    end
  end
end
