require "rails_helper"

RSpec.describe Ability do
  subject(:ability) { Ability.new(user, subject_resource, stub_controller) }
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let(:stub_controller) { OpenStruct.new }
  let(:subject_resource) { facility }

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

  shared_examples_for "it can read notifications" do
    it { expect(ability.can?(:read, Notification)).to be true }
  end

  shared_examples_for "it cannot read notifications" do
    it { expect(ability.can?(:read, Notification)).to be false }
  end

  shared_examples_for "it can access problem reservations" do
    it { expect(ability.can?(:show_problems, Reservation)).to be true }
  end

  shared_examples_for "it cannot access problem reservations" do
    it { expect(ability.can?(:show_problems, Reservation)).to be false }
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

    it_behaves_like "it can read notifications"

    describe StoredFile do
      describe "#download" do
        let(:subject_resource) { build_stubbed(:stored_file) }

        it { expect(ability.can?(:download, StoredFile)).to be true }
      end
    end

    it_behaves_like "it can manage training requests"
    it_behaves_like "it can access problem reservations"
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
    it_behaves_like "it can read notifications"
    it_behaves_like "it can access problem reservations"
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: facility) }

    it_behaves_like "it can manage training requests"
    it_behaves_like "it cannot read notifications"
    it_behaves_like "it cannot access problem reservations"
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_behaves_like "it can create but not manage training requests"
    it_behaves_like "it can read notifications"
    it_behaves_like "it cannot access problem reservations"
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it_behaves_like "it can create but not manage training requests"

    %i(sample_result template_result).each do |file_type|
      describe "downloading a #{file_type}" do
        let(:controller_method) { file_type.to_s.pluralize.to_sym }
        let(:subject_resource) { order_detail }

        let(:stored_file) do
          build(:stored_file,
            file_type: file_type,
            order_detail: order_detail,
            product: product,
          )
        end
        let(:order_detail) { order.order_details.first }
        let(:order) { create(:purchased_order, product: product) }
        let(:product) { create(:setup_instrument, facility: facility) }

        context "for an order belonging to the user" do
          let(:user) { order.user }

          it "is allowed to download" do
            expect(ability.can?(controller_method, order_detail)).to be true
          end
        end

        context "for an order that does not belong to the user" do
          let(:user) { create(:user) }

          it "is not allowed to download" do
            expect(ability.can?(controller_method, order_detail)).to be false
          end
        end
      end
    end

    it_behaves_like "it cannot read notifications"
    it_behaves_like "it cannot access problem reservations"
  end
end
