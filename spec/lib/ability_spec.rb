require "rails_helper"

RSpec.describe Ability do
  subject(:ability) { Ability.new(user, subject_resource, stub_controller) }
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let(:stub_controller) { OpenStruct.new }
  let(:subject_resource) { facility }

  shared_examples_for "it can not manage training requests" do
    let(:subject_resource) { create(:training_request, product: instrument) }

    %i(read update delete index).each do |action|
      it { is_expected.not_to be_allowed_to(action, TrainingRequest) }
    end
  end

  shared_examples_for "it can destroy admistrative reservations" do
    let(:order) { build_stubbed(:order) }
    let(:order_detail) { build_stubbed(:order_detail, order: order) }

    context "with a regular reservation" do
      let(:reservation) { Reservation.new(order_detail: order_detail) }

      it { is_expected.not_to be_allowed_to(:destroy, reservation) }
    end

    context "with an admin reservation" do
      let(:reservation) { Reservation.new(order_detail_id: nil) }

      it { is_expected.to be_allowed_to(:destroy, reservation) }
    end
  end

  describe "account manager" do
    let(:user) { create(:user, :account_manager) }

    it { is_expected.to be_allowed_to(:manage_users, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:read, Notification) }
    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.not_to be_allowed_to(:disputed, Order) }
    it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
    it { is_expected.not_to be_allowed_to(:administer, User) }
    it { is_expected.not_to be_allowed_to(:suspend, Account) }
    it { is_expected.not_to be_allowed_to(:unsuspend, Account) }
    it { is_expected.not_to be_allowed_to(:batch_update, Order) }
    it { is_expected.not_to be_allowed_to(:batch_update, Reservation) }

    context "in a single facility" do
      it { is_expected.not_to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.not_to be_allowed_to(:manage, AccountUser) }
      it { is_expected.not_to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:switch_to, User) }
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { is_expected.to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.to be_allowed_to(:manage, AccountUser) }
      it { is_expected.to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:switch_to, User) }
    end

    context "in no facility" do
      let(:facility) { nil }

      it { is_expected.to be_allowed_to(:manage, AccountUser) }
      it { is_expected.to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:switch_to, User) }
    end
  end

  describe "administrator" do
    let(:user) { create(:user, :administrator) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
        end
      end
    end

    it { is_expected.to be_allowed_to(:read, Notification) }

    describe StoredFile do
      describe "#download" do
        let(:subject_resource) { build_stubbed(:stored_file) }

        it { is_expected.to be_allowed_to(:download, StoredFile) }
      end
    end

    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.not_to be_allowed_to(:manage_users, Facility.cross_facility) }

    context "in a single facility" do
      it { is_expected.to be_allowed_to(:manage, User) }
      it { is_expected.to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.to be_allowed_to(:manage_billing, facility) }
      it { is_expected.to be_allowed_to(:batch_update, Order) }
      it { is_expected.to be_allowed_to(:batch_update, Reservation) }
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      it { is_expected.not_to be_allowed_to(:manage, User) }
      it { is_expected.not_to be_allowed_to(:manage_accounts, facility) }
      it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
    end

    context "in no facility" do
      let(:facility) { nil }

      it { is_expected.not_to be_allowed_to(:manage, User) }
    end
  end

  describe "billing administrator", feature_setting: { billing_administrator: true } do
    let(:user) { create(:user, :billing_administrator) }

    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:manage, Journal) }
    it { is_expected.to be_allowed_to(:manage, OrderDetail) }
    it { is_expected.to be_allowed_to(:manage, Order) }
    it { is_expected.to be_allowed_to(:manage, Reservation) }

    it "cannot administer resources" do
      is_expected.not_to be_allowed_to(:administer, Order)
      is_expected.not_to be_allowed_to(:administer, OrderDetail)
      is_expected.not_to be_allowed_to(:administer, Reservation)
      is_expected.not_to be_allowed_to(:manage_users, Facility.cross_facility)
    end

    context "in a single facility" do
      it { is_expected.to be_allowed_to(:manage_billing, Facility.cross_facility) }
      it { is_expected.not_to be_allowed_to(:manage_billing, facility) }
      it { is_expected.not_to be_allowed_to(:transactions, facility) }
    end

    context "in cross-facility" do
      let(:facility) { Facility.cross_facility }

      %i(disputed_orders manage_billing movable_transactions transactions).each do |action|
        it { is_expected.to be_allowed_to(action, facility) }
      end
    end

    context "in no facility" do
      let(:facility) { nil }

      it { is_expected.to be_allowed_to(:manage_billing, Facility.cross_facility) }
    end
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:disputed, Order) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it { is_expected.to be_allowed_to(:batch_update, Reservation) }
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.to be_allowed_to(:switch_to, User) }

    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "facility director" do
    let(:user) { create(:user, :facility_director, facility: facility) }

    context "managing price groups" do
      context "when the price group has a facility" do
        let(:subject_resource) { create(:price_group, facility: facility) }

        it { is_expected.to be_allowed_to(:manage, UserPriceGroupMember) }
      end

      context "when the price group is global" do
        let(:subject_resource) { create(:price_group, :global) }

        it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }

        context "when it's the cancer center price group" do
          let(:subject_resource) { create(:price_group, :cancer_center) }

          it { is_expected.not_to be_allowed_to(:manage, UserPriceGroupMember) }
        end
      end
    end

    it { is_expected.to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:disputed, Order) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it { is_expected.to be_allowed_to(:batch_update, Reservation) }
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.to be_allowed_to(:switch_to, User) }
    it { is_expected.not_to be_allowed_to(:manage_accounts, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:manage_billing, Facility.cross_facility) }
    it { is_expected.not_to be_allowed_to(:manage_users, Facility.cross_facility) }
    it_behaves_like "it can destroy admistrative reservations"
  end

  shared_examples_for "it has common staff abilities" do
    it { is_expected.not_to be_allowed_to(:disputed, Order) }
    it { is_expected.not_to be_allowed_to(:manage, Account) }
    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.to be_allowed_to(:batch_update, Order) }
    it { is_expected.to be_allowed_to(:batch_update, Reservation) }
    it { is_expected.to be_allowed_to(:read, Notification) }
    it { is_expected.to be_allowed_to(:administer, User) }
    it { is_expected.to be_allowed_to(:switch_to, User) }
    it { is_expected.to be_allowed_to(:read, UserPriceGroupMember) }

    it_behaves_like "it can destroy admistrative reservations"
  end

  describe "senior staff" do
    let(:user) { create(:user, :senior_staff, facility: facility) }

    it_behaves_like "it has common staff abilities"
    it { is_expected.to be_allowed_to(:manage, TrainingRequest) }
  end

  describe "staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_behaves_like "it has common staff abilities"
    it { is_expected.to be_allowed_to(:create, TrainingRequest) }
    it_behaves_like "it can not manage training requests"
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_allowed_to(:manage, Account) }
    it { is_expected.to be_allowed_to(:create, TrainingRequest) }
    it_behaves_like "it can not manage training requests"
    it { is_expected.not_to be_allowed_to(:switch_to, User) }

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
            is_expected.to be_allowed_to(controller_method, order_detail)
          end
        end

        context "for an order that does not belong to the user" do
          let(:user) { create(:user) }

          it "is not allowed to download" do
            is_expected.not_to be_allowed_to(controller_method, order_detail)
          end
        end
      end
    end

    context "when the user has notifications" do
      let(:order) { create(:purchased_order, product: product) }
      let(:product) { create(:instrument_requiring_approval) }

      before(:each) do
        merge_to_order = order.dup
        merge_to_order.save!
        order.update_attribute(:merge_with_order_id, merge_to_order.id)
        MergeNotification.create_for!(user, order.order_details.first.reload)
      end

      it { is_expected.to be_allowed_to(:read, Notification) }
    end

    context "when the user has no notifications" do
      it { is_expected.not_to be_allowed_to(:read, Notification) }
    end

    it { is_expected.not_to be_allowed_to(:show_problems, Reservation) }
    it { is_expected.not_to be_allowed_to(:disputed, Order) }
    it { is_expected.not_to be_allowed_to(:manage, User) }
  end
end
