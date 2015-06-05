require "spec_helper"

describe Ability do
  subject(:ability) { Ability.new(user, subject_resource, stub_controller) }
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let(:stub_controller) { OpenStruct.new }

  shared_examples_for "it can manage price group members" do
    it "can manage its members" do
      expect(ability.can?(:manage, UserPriceGroupMember)).to be true
    end
  end

  shared_examples_for "it cannot manage price group members" do
    it "can manage its members" do
      expect(ability.can?(:manage, UserPriceGroupMember)).to be false
    end
  end

  shared_examples_for "it can manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    it "can manage training requests" do
      expect(ability.can?(:manage, TrainingRequest)).to be true
    end
  end

  shared_examples_for "it can create but not manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    it "can create a training request" do
      expect(ability.can?(:create, TrainingRequest)).to be true
    end

    %i(read update delete index).each do |action|
      it "cannot #{action} training requests" do
        expect(ability.can?(action, TrainingRequest)).to be false
      end
    end
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it_behaves_like "it can manage price group members"
        end
      end
    end

    it_behaves_like "it can manage training requests"
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: facility) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it_behaves_like "it can manage price group members"
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it_behaves_like "it cannot manage price group members"

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it_behaves_like "it cannot manage price group members"
        end
      end
    end

    it_behaves_like "it can manage training requests"
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: facility) }

    it_behaves_like "it can manage training requests"
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_behaves_like "it can create but not manage training requests"
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it_behaves_like "it can create but not manage training requests"
  end
end
