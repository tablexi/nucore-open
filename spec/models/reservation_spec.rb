require "rails_helper"

RSpec.describe Reservation do
  include DateHelper

  subject(:reservation) do
    instrument.reservations.create(
      reserve_start_date: 1.day.from_now.to_date,
      reserve_start_hour: 10,
      reserve_start_min: 0,
      reserve_start_meridian: "am",
      duration_mins: 60,
      split_times: true,
    )
  end

  let(:facility) { create(:facility) }
  let(:facility_account) do
    facility.facility_accounts.create(attributes_for(:facility_account))
  end
  let(:instrument) { @instrument }

  before(:each) do
    @instrument = create(:instrument, facility_account_id: facility_account.id, facility: facility, reserve_interval: 15)
    # add rule, available every day from 12 am to 5 pm, 60 minutes duration
    @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule).merge(start_hour: 0, end_hour: 17))
    allow_any_instance_of(Reservation).to receive(:admin?).and_return(false)
  end

  describe ".upcoming_offline", :time_travel do
    subject { described_class.upcoming_offline(1.year.from_now) }
    let(:now) { Time.current }

    context "when the instrument is down" do
      let!(:instrument) { FactoryGirl.create(:setup_instrument, :offline) }

      context "and a user reservation exists starting now" do
        context "when the order_detail.state is :new" do

          context "when it is purchased (not in the cart)" do
            let!(:reservation) do
              FactoryGirl.create(:purchased_reservation,
                                 product: instrument,
                                 reserve_start_at: now)
            end

            it { is_expected.to eq [reservation] }
          end

          context "when it is unpurchased (in the cart)" do
            let!(:reservation) do
              FactoryGirl.create(:setup_reservation,
                                 product: instrument,
                                 reserve_start_at: now)
            end

            it { is_expected.to be_blank }
          end
        end

        context "when the order_detail.state is :inprocess" do
          let!(:reservation) do
            FactoryGirl.create(:purchased_reservation,
                               :inprocess,
                               product: instrument,
                               reserve_start_at: now)
          end

          it { is_expected.to eq [reservation] }
        end

        context "when the order_detail.state is :complete with no actual_end_at" do
          let!(:reservation) do
            FactoryGirl.create(:purchased_reservation, :long_running, product: instrument)
          end

          before(:each) do
            reservation.order_detail.update_attribute(:state, :complete)
          end

          it { is_expected.to be_blank }
        end

        context "when the order_detail.state is :reconciled with no actual_end_at" do
          let!(:reservation) do
            FactoryGirl.create(:completed_reservation, :long_running, product: instrument)
          end

          before(:each) do
            reservation.order_detail.update_attribute(:state, :reconciled)
          end

          it { is_expected.to be_blank }
        end
      end
    end
  end

  describe "#admin_editable?" do
    context "when the reservation has been persisted" do
      context "and has been canceled" do
        subject(:reservation) { create(:setup_reservation, :canceled) }

        it { expect(reservation).not_to be_admin_editable }
      end

      context "and has not been canceled" do
        subject(:reservation) { create(:setup_reservation) }

        it { expect(reservation).to be_admin_editable }
      end
    end

    context "when the reservation has not been persisted" do
      subject(:reservation) { build(:reservation) }

      it { expect(reservation).to be_admin_editable }
    end
  end

  describe "#admin_removable?" do
    it { is_expected.to be_admin_removable }
  end

  describe "#can_cancel?" do
    context "when the reservation has a canceled_at timestamp" do
      before { allow(reservation).to receive(:canceled_at).and_return(1.day.ago) }

      it { is_expected.not_to be_can_cancel }
    end

    context "when the reservation does not have a canceled_at timestamp" do
      before(:each) do
        allow(reservation).to receive(:actual_end_at).and_return(actual_end_at)
        allow(reservation).to receive(:actual_start_at).and_return(actual_start_at)
        allow(reservation).to receive(:reserve_start_at).and_return(reserve_start_at)
      end

      shared_examples_for "the reservation has actuals" do
        context "when it has an actual start time" do
          let(:actual_start_at) { 1.hour.ago }

          context "and an actual end time" do
            let(:actual_end_at) { 1.minute.ago }

            it { is_expected.not_to be_can_cancel }
          end

          context "and no actual end time" do
            let(:actual_end_at) { nil }

            it { is_expected.not_to be_can_cancel }
          end
        end
      end

      context "when the reservation start time is in the past" do
        let(:reserve_start_at) { 1.minute.ago }

        it_behaves_like "the reservation has actuals"

        context "when it has no actual start time" do
          let(:actual_start_at) { nil }

          context "and no actual end time" do
            let(:actual_end_at) { nil }

            it { is_expected.not_to be_can_cancel }
          end

          context "but an actual end time" do
            let(:actual_end_at) { 1.minute.ago }

            it { is_expected.not_to be_can_cancel }
          end
        end
      end

      context "when the reservation start time is in the future" do
        let(:reserve_start_at) { 1.hour.from_now }

        it_behaves_like "the reservation has actuals"

        context "when it has no actual start time" do
          let(:actual_start_at) { nil }

          context "and no actual end time" do
            let(:actual_end_at) { nil }

            it { is_expected.to be_can_cancel }
          end

          context "but an actual end time" do
            let(:actual_end_at) { 1.minute.ago }

            it { is_expected.not_to be_can_cancel }
          end
        end
      end
    end
  end

  describe "#end_at_required?" do
    it { is_expected.to be_end_at_required }
  end

  describe "#locked?" do
    before(:each) do
      allow(reservation).to receive(:admin_editable?).and_return(admin_editable?)
      allow(reservation).to receive(:can_edit_actuals?).and_return(can_edit_actuals?)
    end

    context "when editable by admins" do
      let(:admin_editable?) { true }

      context "and actuals are editable" do
        let(:can_edit_actuals?) { true }

        it { expect(reservation).not_to be_locked }
      end

      context "and actuals are not editable" do
        let(:can_edit_actuals?) { false }

        it { expect(reservation).not_to be_locked }
      end
    end

    context "when not editable by admins" do
      let(:admin_editable?) { false }

      context "and actuals are editable" do
        let(:can_edit_actuals?) { true }

        it { expect(reservation).not_to be_locked }
      end

      context "and actuals are not editable" do
        let(:can_edit_actuals?) { false }

        it { expect(reservation).to be_locked }
      end
    end
  end

  describe "#reservation_changed?" do
    context "when altering the reservation start time" do
      it "becomes true" do
        expect { reservation.reserve_start_at += 1 }
          .to change(reservation, :reservation_changed?).from(false).to(true)
      end
    end

    context "when altering the reservation end time" do
      it "becomes true" do
        expect { reservation.reserve_end_at += 1 }
          .to change(reservation, :reservation_changed?).from(false).to(true)
      end
    end

    context "when the reservation times do not change" do
      it "remains false" do
        expect do
          reservation.reserve_start_at += 0
          reservation.reserve_end_at += 0
        end.not_to change(reservation, :reservation_changed?).from(false)
      end
    end
  end

  it "allows starting of a reservation, whose duration is equal to the max duration, within the grace period" do
    reservation.product.update_attribute :max_reserve_mins, reservation.duration_mins

    travel_to_and_return(reservation.reserve_start_at - 2.minutes) do # in grace period
      expect { reservation.start_reservation! }.to_not raise_error
      expect(reservation.errors).to be_empty
    end
  end

  context "create using virtual attributes" do
    it "should create using date, integer values" do
      assert reservation.valid?
      expect(reservation.reload.duration_mins).to eq(60)
      expect(reservation.reserve_start_hour).to eq(10)
      expect(reservation.reserve_start_min).to eq(0)
      expect(reservation.reserve_start_meridian).to eq("am")
      expect(reservation.reserve_end_hour).to eq(11)
      expect(reservation.reserve_end_min).to eq(0)
      expect(reservation.reserve_end_meridian).to eq("AM")
    end

    it "should create using string values" do
      @reservation = instrument.reservations.create(reserve_start_date: (Date.today + 1.day).to_s,
                                                    reserve_start_hour: "10",
                                                    reserve_start_min: "0",
                                                    reserve_start_meridian: "am",
                                                    duration_mins: "120",
                                                    split_times: true)
      assert @reservation.valid?
      expect(@reservation.reload.duration_mins).to eq(120)
      expect(@reservation.reserve_start_hour).to eq(10)
      expect(@reservation.reserve_start_min).to eq(0)
      expect(@reservation.reserve_start_meridian).to eq("am")
      expect(@reservation.reserve_end_hour).to eq(12)
      expect(@reservation.reserve_end_min).to eq(0)
      expect(@reservation.reserve_end_meridian).to eq("PM")
    end
  end

  describe "#canceled?" do
    subject(:reservation) do
      instrument.reservations.create(reserve_start_date: (Date.today + 1.day).to_s,
                                     reserve_start_hour: "10",
                                     reserve_start_min: "0",
                                     reserve_start_meridian: "am",
                                     duration_mins: "120",
                                     split_times: true)
    end

    it { is_expected.to be_valid }
    it { is_expected.not_to be_canceled }

    context "when canceled_at is set" do
      before { reservation.canceled_at = Time.current }
      it { is_expected.to be_canceled }
    end
  end

  context "with order details" do
    subject(:reservation) { @reservation1 }
    let(:instrument) { @instrument }

    before :each do
      @price_group = create(:price_group, facility: facility)
      @instrument_pp = FactoryGirl.create(:instrument_price_policy, product: @instrument, price_group: @price_group)
      @user          = FactoryGirl.create(:user)
      @account       = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      create(:account_price_group_member, account: @account, price_group: @price_group)
      @order = @user.orders.create(attributes_for(:order, created_by: @user.id, account: @account, facility: facility))
      order_attrs    = FactoryGirl.attributes_for(:order_detail, product_id: @instrument.id, quantity: 1)
      @detail1       = @order.order_details.create(order_attrs.merge(account: @account))
      @detail2       = @order.order_details.create(order_attrs)

      @instrument.min_reserve_mins = 15
      @instrument.save

      @reservation1 = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                     reserve_start_hour: 10,
                                                     reserve_start_min: 0,
                                                     reserve_start_meridian: "am",
                                                     duration_mins: 30,
                                                     order_detail: @detail1,
                                                     split_times: true)
    end

    context "#can_customer_edit?" do
      shared_examples_for "a customer is allowed to edit" do
        it "allows a customer to edit" do
          expect(reservation.can_customer_edit?).to eq true
        end
      end

      shared_examples_for "a customer is not allowed to edit" do
        it "does not allow a customer to edit" do
          expect(reservation.can_customer_edit?).to eq false
        end
      end

      context "the reservation has been canceled" do
        before { reservation.update_attribute(:canceled_at, 1.hour.ago) }

        it_behaves_like "a customer is not allowed to edit"
      end

      context "the reservation has not been canceled" do
        before { reservation.update_attribute(:canceled_at, nil) }

        context "it is complete" do
          before :each do
            reservation.order_detail.update_attribute(:state, "complete")
          end

          it_behaves_like "a customer is not allowed to edit"
        end

        context "the reservation is not complete" do
          before { reservation.order_detail.update_attribute(:state, "new") }

          context "the reservation has begun" do
            before :each do
              reservation.update_columns(reserve_start_at: 3.hours.ago, actual_start_at: 3.hours.ago)
            end

            context "there is a following reservation" do
              before do
                instrument.reservations.create!(
                  reserve_start_at: reservation.reserve_end_at,
                  reserve_end_at: reservation.reserve_end_at + 1.hour,
                )
              end

              it_behaves_like "a customer is not allowed to edit"
            end

            context "there is no following reservation" do
              it_behaves_like "a customer is allowed to edit"
            end

            context "the instrument has a reservation lock window" do
              let(:current_time) { Time.zone.now }

              before :each do
                instrument.update_attribute(:lock_window, 12)
                reservation.reload
              end

              context "within the grace period" do
                before do
                  reservation.update_columns(reserve_start_at: current_time + 5.minutes, actual_start_at: current_time)
                end

                it_behaves_like "a customer is allowed to edit"
              end
            end
          end

          context "the reservation has not yet begun" do
            before :each do
              reservation.update_attribute(:reserve_start_at, 6.hours.from_now)
            end

            context "the instrument has no lock window" do
              before { instrument.update_attribute(:lock_window, 0) }

              it_behaves_like "a customer is allowed to edit"
            end

            context "the instrument has a reservation lock window" do
              let(:window_hours) { 12 }

              before :each do
                @current_time = Time.zone.now
                instrument.update_attribute(:lock_window, window_hours)
                reservation.reload
              end

              after { travel_to(@current_time) }

              context "before the lock window begins" do
                before :each do
                  travel_to(reservation.reserve_start_at - (window_hours + 2).hours)
                end

                it_behaves_like "a customer is allowed to edit"
              end

              context "after the lock window has begun" do
                before :each do
                  travel_to(reservation.reserve_start_at - (window_hours - 2).hours)
                end

                it_behaves_like "a customer is not allowed to edit"
              end
            end
          end
        end
      end
    end

    context "#earliest_possible" do
      it "shouldn't throw an exception if Instrument#next_available_reservation and_return nil" do
        allow_any_instance_of(Instrument).to receive(:next_available_reservation).and_return nil
        @reservation1.earliest_possible
      end

      it "does not hang on restricted instrument if user does not have access" do
        expect(@reservation1.earliest_possible).to be
        @instrument.update_attributes(requires_approval: true)
        expect(@reservation1.reload.earliest_possible).to be_nil
      end

      it "does not look at time after the reservation" do
        @instrument.update_attributes(max_reserve_mins: nil, reserve_interval: 1)
        @instrument.schedule_rules.update_all(start_hour: 0, end_hour: 24)
        # Make sure there is no time between now and the reservation
        order = @user.orders.create(attributes_for(:order, created_by: @user.id, account: @account, facility: facility))
        order_attrs   = attributes_for(:order_detail, product_id: @instrument.id, quantity: 1, account: @account)
        detail1       = order.order_details.create(order_attrs)
        res = @instrument.reservations.create(reserve_start_at: Time.zone.now, reserve_end_at: @reservation1.reserve_start_at, order_detail: detail1)
        detail2 = order.order_details.create(order_attrs)
        res2 = @instrument.reservations.create(reserve_start_at: @reservation1.reserve_end_at, reserve_end_at: @reservation1.reserve_end_at + 1.day, order_detail: detail2)
        res.order.validate_order!
        res.order.purchase!
        expect(@reservation1.reload.earliest_possible).to be_nil
      end
    end

    it "should be the same order" do
      expect(@reservation1.order).to eq(@detail1.order)
    end

    it "should not allow two reservations with the same order detail id" do
      reservation2 = @instrument.reservations.new(reserve_start_date: Date.today + 1.day, reserve_start_hour: 10,
                                                  reserve_start_min: 0, reserve_start_meridian: "am",
                                                  duration_mins: 30, order_detail: @reservation1.order_detail)
      assert !reservation2.save
      expect(reservation2.errors[:order_detail]).not_to be_nil
    end

    it "should be the same user" do
      expect(@reservation1.user).to eq(@detail1.order.user)
    end

    it "should be the same account" do
      expect(@detail1.account).not_to be_nil
      expect(@reservation1.account).to eq(@detail1.account)
    end

    it "should be the same owner" do
      expect(@detail1.account.owner).not_to be_nil
      expect(@reservation1.owner).to eq(@detail1.account.owner)
    end

    it "should not allow reservations to conflict with an existing reservation in the same order" do
      expect(@reservation1).to be_valid

      @reservation2 = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                     reserve_start_hour: 10,
                                                     reserve_start_min: 0,
                                                     reserve_start_meridian: "am",
                                                     duration_mins: 30,
                                                     order_detail: @detail2,
                                                     split_times: true)
      expect(@reservation2).not_to be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]

      @reservation2 = @instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                      reserve_start_hour: 10,
                                                      reserve_start_min: 15,
                                                      reserve_start_meridian: "am",
                                                      duration_mins: 30,
                                                      order_detail: @detail2,
                                                      split_times: true)
      expect(@reservation2).not_to be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]

      @reservation2 = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                     reserve_start_hour: 9,
                                                     reserve_start_min: 45,
                                                     reserve_start_meridian: "am",
                                                     duration_mins: 30,
                                                     order_detail: @detail2,
                                                     split_times: true)
      expect(@reservation2).not_to be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]
    end

    it "should allow reservations with the same time and date on different instruments" do
      expect(@reservation1).to be_valid

      @reservation2 = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                     reserve_start_hour: 10,
                                                     reserve_start_min: 0,
                                                     reserve_start_meridian: "am",
                                                     duration_mins: 30,
                                                     order_detail: @detail2,
                                                     split_times: true)

      expect(@reservation2).not_to be_does_not_conflict_with_other_reservation

      @instrument2 = create(:instrument, facility: facility, facility_account: facility_account)

      @reservation2.product = @instrument2
      expect(@reservation2).to be_does_not_conflict_with_other_reservation
    end

    context "moving" do

      before(:each) { @morning = Time.zone.parse("#{Date.today} 10:31:00") }

      context "when the reserved instrument is online" do
        it { is_expected.to be_startable_now }
      end

      context "when the reserved instrument is offline" do
        let(:instrument) { FactoryGirl.create(:setup_instrument, :offline) }

        it { is_expected.not_to be_startable_now }
      end

      it "should return the earliest possible time slot" do
        expect(human_date(@reservation1.reserve_start_at)).to eq(human_date(@morning + 1.day))

        earliest = nil
        travel_to_and_return(@morning) do
          earliest = @reservation1.earliest_possible
        end
        expect(human_date(earliest.reserve_start_at)).to eq(human_date(@morning))

        new_min = 0

        (@morning.min..60).each do |min|
          new_min = min == 60 ? 0 : min
          expect(earliest.reserve_start_at.min).to(eq(new_min)) && break if new_min % @rule.product.reserve_interval == 0
        end

        expect(earliest.reserve_start_at.hour).to eq(new_min == 0 ? @morning.hour + 1 : @morning.hour)
        expect(earliest.reserve_end_at - earliest.reserve_start_at).to eq(@reservation1.reserve_end_at - @reservation1.reserve_start_at)
      end

      it "should not be moveable if the reservation is in the grace period" do
        @instrument.update_attributes(reserve_interval: 1)
        @reservation1.duration_mins = 1
        travel_to_and_return(@reservation1.reserve_start_at - 4.minutes) do
          expect(@reservation1).to_not be_startable_now
        end
      end

      it "should not be moveable if the reservation is canceled" do
        expect(@reservation1).to be_startable_now
        @reservation1.canceled_at = Time.zone.now
        expect(@reservation1).not_to be_startable_now
      end

      it "should not be moveable if there is not a time slot earlier than this one" do
        expect(@reservation1).to be_startable_now
        expect(@reservation1.move_to_earliest).to be true
        expect(@reservation1).not_to be_startable_now
        expect(@reservation1.move_to_earliest).to be false
        expect(@reservation1.errors.messages).to eq(base: ["Sorry, but your reservation can no longer be moved."])
      end

      it "should update the reservation to the earliest available" do
        # if earliest= and move_to_earliest span a second, the test fails
        earliest = @reservation1.earliest_possible
        expect(@reservation1.reserve_start_at).not_to eq(earliest.reserve_start_at)
        expect(@reservation1.reserve_end_at).not_to eq(earliest.reserve_end_at)
        expect(@reservation1.move_to_earliest).to be true
        expect(@reservation1.reserve_start_at.change(sec: 0).to_i).to eq(earliest.reserve_start_at.change(sec: 0).to_i)
        expect(@reservation1.reserve_end_at.change(sec: 0).to_i).to eq(earliest.reserve_end_at.change(sec: 0).to_i)
      end

      it "should be able to move to now, but overlapping the current" do
        @reservation1.update_attributes!(reserve_start_at: 30.minutes.from_now, reserve_end_at: 60.minutes.from_now)
        allow(@reservation1.order).to receive(:cart_valid?).and_return(true)
        @reservation1.order.validate_order!
        @reservation1.order.purchase!

        expect(@reservation1.earliest_possible).to be
      end

      context "with schedule rules" do
        let(:tomorrow_noon) { 1.day.from_now.change(hour: 12, min: 00) }
        before do
          ScheduleRule.destroy_all
          @instrument.schedule_rules.reload
          @instrument.update_attributes(requires_approval: true)
          @everybody_schedule_rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
          group1 = FactoryGirl.create(:product_access_group, product: @instrument)
          @everybody_schedule_rule.product_access_groups << group1
          group1.product_users.create(product: @instrument, user: @user, approved_by: @user.id)
          @restricted_schedule_rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: 17, end_hour: 24))
          @restricted_schedule_rule.product_access_groups << FactoryGirl.create(:product_access_group, product: @instrument)
          @reservation1.reload
        end

        it "should not be able to move to a schedule rule the user is not part of" do
          @reservation1.update_attributes!(reserve_start_at: tomorrow_noon, reserve_end_at: tomorrow_noon + 30.minutes)
          # 4:45pm today will be in the restricted schedule rule
          travel_to_and_return(Time.current.change(hour: 16, min: 45, sec: 0)) do
            expect(@reservation1.earliest_possible.reserve_start_at).to eq(1.day.from_now.change(hour: 9, min: 0, sec: 0))
          end
        end
      end
    end

    context "requires_but_missing_actuals?" do

      it "should be true when there is a usage rate but no actuals" do
        # @instrument_pp.update_attributes!(:usage_rate => 5)

        expect(@reservation1.actual_start_at).to be_nil
        expect(@reservation1.actual_end_at).to be_nil
        # @reservation1.order_detail.price_policy=@instrument_pp
        # assert @reservation1.save

        expect(@reservation1).to be_requires_but_missing_actuals
      end

      it "should be true when there is no policy assigned, but the one it would use requires actuals" do
        expect(@reservation1.actual_start_at).to be_nil
        expect(@reservation1.actual_end_at).to be_nil
        @instrument_pp.update_attributes(usage_rate: 5)

        assert @reservation1.save
        expect(@instrument.cheapest_price_policy(@reservation1.order_detail, @reservation1.reserve_end_at)).to eq(@instrument_pp)
        expect(@reservation1).to be_requires_but_missing_actuals
      end

      it "should be false when there is no price policy" do
        @reservation1.actual_start_at = 1.day.ago
        @reservation1.actual_end_at = 1.day.ago + 1.hour
        @instrument.instrument_price_policies.clear
        assert @reservation1.save
        expect(@instrument.cheapest_price_policy(@reservation1.order_detail)).to be_nil
        expect(@reservation1.order_detail.price_policy).to be_nil
        expect(@reservation1).not_to be_requires_but_missing_actuals
      end

      it "should be false when price policy has no usage rate" do
        @instrument_pp.update_attribute :usage_rate, 0

        @reservation1.order_detail.price_policy = @instrument_pp
        @reservation1.actual_start_at = 1.day.ago
        @reservation1.actual_end_at = 1.day.ago + 1.hour
        assert @reservation1.save

        expect(@reservation1).not_to be_requires_but_missing_actuals
      end

      it "should be false when price policy has zero usage rate" do
        @instrument_pp.usage_rate = 0
        assert @instrument_pp.save

        @reservation1.order_detail.price_policy = @instrument_pp
        @reservation1.actual_start_at = 1.day.ago
        @reservation1.actual_end_at = 1.day.ago + 1.hour
        assert @reservation1.save

        expect(@reservation1).not_to be_requires_but_missing_actuals
      end

      it "should be false when there is a usage rate and actuals" do
        @instrument_pp.usage_rate = 5
        assert @instrument_pp.save

        @reservation1.order_detail.price_policy = @instrument_pp
        @reservation1.actual_start_at = 1.day.ago
        @reservation1.actual_end_at = 1.day.ago + 1.hour
        assert @reservation1.save

        expect(@reservation1).not_to be_requires_but_missing_actuals
      end

    end

    context "ordered_on_behalf_of?" do
      it "should return true if the associated order was ordered by someone else" do
        @user2 = FactoryGirl.create(:user)
        @reservation1.order.update_attributes(created_by_user: @user2)
        expect(@reservation1.reload).to be_ordered_on_behalf_of
      end
      it "should return false if the associated order was not ordered on behalf of" do
        user = @reservation1.order_detail.order.user
        @reservation1.order_detail.order.update_attributes(created_by_user: user)
        @reservation1.reload
        expect(@reservation1.reload).not_to be_ordered_on_behalf_of
      end
      it "should return false for admin reservations" do
        @admin_reservation = FactoryGirl.create(:reservation, product: @instrument)
        expect(@admin_reservation).not_to be_ordered_on_behalf_of
      end

    end
  end

  context "conflicting reservations" do
    let!(:reservation) do
      instrument.reservations.create!(reserve_start_date: Date.today + 1.day,
                                      reserve_start_hour: 10,
                                      reserve_start_min: 0,
                                      reserve_start_meridian: "am",
                                      duration_mins: "60",
                                      split_times: true)
    end

    let(:conflicting_reservation) do
      res = instrument.reservations.build(reserve_start_date: Date.today + 1.day,
                                          reserve_start_hour: 10,
                                          reserve_start_min: 0,
                                          reserve_start_meridian: "am",
                                          duration_mins: "60",
                                          split_times: true)
      res.valid?
      res
    end

    let(:conflicting_admin_reservation) do
      res = instrument.reservations.build(reserve_start_date: Date.today + 1.day,
                                          reserve_start_hour: 10,
                                          reserve_start_min: 0,
                                          reserve_start_meridian: "am",
                                          duration_mins: "60",
                                          split_times: true)
      res.valid?
      allow(res).to receive(:admin?).and_return(true)
      res
    end

    it "should be a conflicting reservation" do
      expect(conflicting_reservation).not_to be_does_not_conflict_with_other_reservation
    end

    it "should be invalid" do
      expect(conflicting_reservation).not_to be_valid
      expect(conflicting_reservation.errors[:base]).to include "The reservation conflicts with another reservation."
    end

    it "should allow an admin reservation to overlap" do
      expect(conflicting_admin_reservation).to be_valid
    end

    context "and the reservation has started" do
      before :each do
        # Actual start must be in the past
        reservation.update_attributes! reserve_start_at: 30.minutes.ago,
                                       reserve_end_at: 30.minutes.from_now,
                                       actual_start_at: 30.minutes.ago

        conflicting_reservation.assign_attributes reserve_start_at: 30.minutes.ago,
                                                  reserve_end_at: 30.minutes.from_now
      end

      it "should be a conflict" do
        expect(conflicting_reservation).not_to be_valid
      end

      context "and ended" do
        before :each do
          reservation.update_attributes!(actual_end_at: 20.minutes.ago)
        end

        it "should not conflict" do
          expect(conflicting_reservation).to be_valid
        end
      end
    end

    context "overlapping scheduling rules" do
      context "completely within a blacked out time" do
        before :each do
          @reservation = instrument.reservations.build(reserve_start_date: Date.today + 1.day,
                                                       reserve_start_hour: 6,
                                                       reserve_start_min: 0,
                                                       reserve_start_meridian: "pm",
                                                       duration_mins: "60",
                                                       split_times: true)
        end

        it "should allow an admin reservation" do
          allow(@reservation).to receive(:admin?).and_return(true)
          expect(@reservation).to be_valid
        end

        it "should not allow a regular reservation" do
          expect(@reservation).not_to be_valid
          expect(@reservation.errors[:base]).to include "The reservation spans time that the instrument is unavailable for reservation"
        end
      end

      context "overlapping a border of blacked out time" do
        before :each do
          @reservation = instrument.reservations.build(reserve_start_date: Date.today + 1.day,
                                                       reserve_start_hour: 5,
                                                       reserve_start_min: 30,
                                                       reserve_start_meridian: "pm",
                                                       duration_mins: "60",
                                                       split_times: true)
        end

        it "should allow an admin reservation" do
          allow(@reservation).to receive(:admin?).and_return(true)
          expect(@reservation).to be_valid
        end

        it "should not allow a regular reservation" do
          expect(@reservation).not_to be_valid
          expect(@reservation.errors[:base]).to include "The reservation spans time that the instrument is unavailable for reservation"
        end
      end
    end
  end

  context "maximum reservation length" do
    before { instrument.update_attribute(:max_reserve_mins, 60) }

    it "does not let reservations exceed the maximum length" do
      @reservation = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 61,
                                                    split_times: true)
      expect(@reservation).not_to be_valid
      expect(@reservation.errors[:base]).to include "The reservation is too long"
    end

    context "when the reservation does not exceed the maximum length" do
      subject(:reservation) do
        instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                       reserve_start_hour: 10,
                                       reserve_start_min: 0,
                                       reserve_start_meridian: "am",
                                       duration_mins: 60,
                                       split_times: true)
      end

      it { is_expected.to be_valid }
    end

    it "should allow admin reservation to exceed the maximum length" do
      @reservation = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 75,
                                                    split_times: true)
      allow(@reservation).to receive(:admin?).and_return(true)
      expect(@reservation).to be_valid
    end
  end

  context "minimum reservation length" do
    before { instrument.update_attribute(:min_reserve_mins, 30) }

    it "does not allow reservations under the minimum length" do
      @reservation = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 29,
                                                    split_times: true)
      expect(@reservation).not_to be_valid
      expect(@reservation.errors[:base]).to include "The reservation is too short"
    end

    it "allows reservations over the minimum length" do
      @reservation = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 30,
                                                    split_times: true)
      expect(@reservation).to be_valid
    end

    it "allows admin reservations less than the minimum length" do
      @reservation = instrument.reservations.create(reserve_start_date: Date.today + 1.day,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 15,
                                                    split_times: true)
      allow(@reservation).to receive(:admin?).and_return(true)
      expect(@reservation).to be_valid
    end
  end

  it "should allow multi-day registrations" do
    # set max reserve to 4 hours
    @instrument.max_reserve_mins = 240
    @instrument.save
    @today        = Date.today
    @tomorrow     = @today + 1.day
    # should not allow multi-day reservation with existing rules
    @reservation = instrument.reservations.create(reserve_start_date: @tomorrow,
                                                  reserve_start_hour: 10,
                                                  reserve_start_min: 0,
                                                  reserve_start_meridian: "pm",
                                                  duration_mins: 240,
                                                  split_times: true)
    assert @reservation.invalid?
    # create rule2 that is adjacent to rule (10 pm to 12 am), allowing multi-day reservations
    @rule2 = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule).merge(start_hour: 22, end_hour: 24))
    assert @rule2.valid?
    @reservation = instrument.reservations.create(reserve_start_date: @tomorrow,
                                                  reserve_start_hour: 10,
                                                  reserve_start_min: 0,
                                                  reserve_start_meridian: "pm",
                                                  duration_mins: 240,
                                                  split_times: true)
    assert @reservation.valid?
  end

  it "allows starting of an instrument even though another reservation is running but over end time", :time_travel do
    now = Time.zone.now
    next_hour = now + 1.hour
    hour_ago = now - 1.hour
    two_hour_ago = hour_ago - 1.hour
    reservation = @instrument.reservations.create reserve_start_at: two_hour_ago, reserve_end_at: hour_ago, actual_start_at: two_hour_ago
    expect(reservation.actual_end_at).to be_nil
    expect(reservation).to be_valid
    reservation = @instrument.reservations.create reserve_start_at: now, reserve_end_at: next_hour
    expect(reservation).to be_can_start_early
  end

  describe '#start_reservation!' do
    it "sets actual start time", :time_travel do
      reservation.start_reservation!
      expect(reservation.actual_start_at).to eq(Time.current)
    end

    context "with a running reservation" do
      let!(:running) do
        start_time = 1.hour.ago - 1.second
        FactoryGirl.create(:setup_reservation,
                           product: instrument,
                           reserve_start_at: start_time,
                           actual_start_at: start_time)
      end

      before do
        order = running.order_detail.order
        order.state = "validated"
        order.purchase!

        reservation.start_reservation!
      end

      it "completes the running reservation" do
        expect(running.reload).to be_complete
      end

      it "sets the orders as a problem order" do
        expect(running.reload).to be_problem
      end

      it "does not set actual_end_at" do
        expect(running.reload.actual_end_at).to be_nil
      end
    end

    context "with a running reservation on a shared calendar" do
      let(:running_instrument) { create(:setup_instrument, schedule: reservation.product.schedule, min_reserve_mins: 1) }
      let!(:running) { create :setup_reservation, product: running_instrument, reserve_start_at: 30.minutes.ago, reserve_end_at: 1.minute.ago, actual_start_at: 30.minutes.ago }

      before do
        order = running.order_detail.order
        order.state = "validated"
        order.purchase!

        running_instrument.instrument_price_policies.destroy_all
        create(:instrument_usage_price_policy, product: running_instrument)

        reservation.start_reservation!
      end

      it "completes the running reservation" do
        expect(running.reload).to be_complete
      end

      it "sets the orders as a problem order" do
        expect(running.reload).to be_problem
      end

      it "does not set actual_end_at" do
        expect(running.reload.actual_end_at).to be_nil
      end
    end

    context "with an complete reservation" do
      let!(:complete) { create :setup_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago, actual_start_at: 2.hours.ago, actual_end_at: 1.hour.ago }

      before do
        order = complete.order_detail.order
        order.state = "validated"
        order.purchase!
      end

      it "does nothing" do
        expect { reservation.start_reservation! }
          .to_not change { complete.reload.attributes }
      end
    end
  end

  context "basic reservation rules" do

    it "should not allow reservations starting before now" do
      @earlier = Date.today - 1
      @reservation = @instrument.reservations.create(reserve_start_date: @earlier, reserve_start_hour: 10,
                                                     reserve_start_min: 0, reserve_start_meridian: "pm",
                                                     duration_mins: 240)
      assert @reservation.invalid?
    end

    it "should not let reservations be made outside the reservation window" do
      skip
    end

    context "schedule rules" do
      before :each do
        @instrument.schedule_rules.destroy_all
        @instrument.schedule_rules.reload
        @instrument.update_attribute :reserve_interval, 15
        @rule_9to5 = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: 9, end_hour: 17))
        @rule_5to7 = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: 17, end_hour: 19))
      end

      it "allows a reservation within the schedule rules" do
        @reservation = instrument.reservations.new(reserve_start_date: Date.today + 1,
                                                   reserve_start_hour: 6,
                                                   reserve_start_min: 0,
                                                   reserve_start_meridian: "pm",
                                                   duration_mins: 60,
                                                   split_times: true)
        expect(@reservation).to be_valid

        @reservation2 = instrument.reservations.new(reserve_start_date: Date.today + 1,
                                                    reserve_start_hour: 10,
                                                    reserve_start_min: 0,
                                                    reserve_start_meridian: "am",
                                                    duration_mins: 60,
                                                    split_times: true)
        expect(@reservation2).to be_valid
      end

      it "should not let reservations occur after times defined by schedule rules" do
        @reservation = @instrument.reservations.new(reserve_start_date: Date.today + 1, reserve_start_hour: 8, reserve_start_min: 0, reserve_start_meridian: "pm", duration_mins: 6)
        expect(@reservation).to be_invalid
      end
      it "should not let reservations occur before times define by schedule rules" do
        @reservation = @instrument.reservations.new(reserve_start_date: Date.today + 1, reserve_start_hour: 5, reserve_start_min: 0, reserve_start_meridian: "am", duration_mins: 60)
        expect(@reservation).to be_invalid
      end

      context "schedule rules with restrictions" do
        before :each do
          @user = FactoryGirl.create(:user)
          @account = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))

          @instrument.update_attributes(requires_approval: true)

          @order = create(:order, user: @user, created_by: @user.id, account: @account, facility: facility)
          @order_detail = FactoryGirl.create(:order_detail, order: @order, product: @instrument)
          # @instrument.update_attributes(:requires_approval => true)

          @restriction_level = @rule_5to7.product_access_groups.create(FactoryGirl.attributes_for(:product_access_group, product: @instrument))
          @instrument.reload
          @reservation = Reservation.new(reserve_start_date: Date.today + 1,
                                         reserve_start_hour: 6,
                                         reserve_start_min: 0,
                                         reserve_start_meridian: "pm",
                                         duration_mins: 60,
                                         order_detail: @order_detail,
                                         product: @instrument,
                                         split_times: true)
        end

        it "should allow a user to reserve if it doesn't require approval" do
          @instrument.update_attributes(requires_approval: false)
          expect(@reservation).to be_valid
        end

        it "should not allow a user who is not approved to reserve" do
          expect(@reservation).not_to be_valid
        end
        it "should not allow a user who is approved, but not in the group" do
          @product_user = ProductUser.create(user: @user, product: @instrument, approved_by: @user.id)
          expect(@product_user).not_to be_new_record
          expect(@reservation).not_to be_valid
        end
        it "should allow a user who is approved and part of the restriction group" do
          @product_user = @user.product_users.create(product: @instrument, product_access_group: @restriction_level, approved_by: @user.id)
          expect(@product_user).not_to be_new_record

          expect(@reservation).to be_valid
        end

        context "admin overrides" do
          before :each do
            # user is not in the restricted group
            @product_user = ProductUser.create(user: @user, product: @instrument, approved_by: @user.id)
            @admin = FactoryGirl.create(:user)
            UserRole.grant(@admin, UserRole::ADMINISTRATOR)
          end

          it "should allow an administrator to save in one of the restricted scheduling rules" do
            @reservation.save_as_user!(@admin)
            # if it raises an exception, we're in trouble
          end
          it "should not allow a regular user to save in a restricted scheduling rule" do
            expect { @reservation.save_as_user!(@user) }.to raise_error(ActiveRecord::RecordInvalid)
          end
          it "should not allow an administrator to save outside of scheduling rules" do
            @reservation.update_attributes(reserve_start_hour: 10)
            expect { @reservation.save_as_user!(@admin) }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

    end
  end

  context "get best possible reservation" do
    before do
      PriceGroupProduct.destroy_all

      @user = FactoryGirl.create(:user)
      @nupg_pgp = FactoryGirl.create(:price_group_product, product: @instrument, price_group: @nupg)

      # Setup a price group with an account for this user
      @price_group1 = FactoryGirl.create(:price_group, facility: facility)
      @pg1_pgp = FactoryGirl.create(:price_group_product, product: @instrument, price_group: @price_group1)
      @account1 = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @account_price_group_member1 = AccountPriceGroupMember.create(FactoryGirl.attributes_for(:account_price_group_member).merge(account: @account1, price_group: @price_group1))

      # Setup a second price groups with another account for this user
      create(:account_price_group_member, account: @account1, price_group: @nupg)
      @user_price_group_member = UserPriceGroupMember.create(FactoryGirl.attributes_for(:user_price_group_member).merge(user: @user, price_group: @nupg))

      # Order against the first account
      @order = Order.create(FactoryGirl.attributes_for(:order).merge(user: @user, account: @account1, created_by: @user.id))
      @order_detail = @order.order_details.create(FactoryGirl.attributes_for(:order_detail).merge(product: @instrument, order_status: @os_new))
      reservation.order_detail = @order_detail
      reservation.save
    end

    it "should find the best reservation window" do
      @pp_short = InstrumentPricePolicy.create(FactoryGirl.attributes_for(:instrument_price_policy, product_id: @instrument.id))
      @pg1_pgp.reservation_window = 30
      assert @pg1_pgp.save
      @pp_long = InstrumentPricePolicy.create(FactoryGirl.attributes_for(:instrument_price_policy, product_id: @instrument.id))
      @nupg_pgp.reservation_window = 60
      assert @nupg_pgp.save
      @price_group1.price_policies << @pp_short
      @nupg.price_policies         << @pp_long

      groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
      assert_equal @pp_long.reservation_window, reservation.longest_reservation_window(groups)
    end
  end

  context "has_actuals?" do
    it "should not have actuals" do
      expect(reservation).not_to be_has_actuals
    end

    it "should have actuals" do
      reservation.actual_start_at = Time.zone.now
      reservation.actual_end_at = Time.zone.now
      expect(reservation).to be_has_actuals
    end
  end

  context "as_calendar_obj" do
    before :each do
      @reservation = instrument.reservations.create!(reserve_start_at: 1.hour.ago,
                                                     duration_mins: 60,
                                                     split_times: true)

      @reserve_start_at_timestamp = @reservation.reserve_start_at.strftime("%a, %d %b %Y %H:%M:%S")
      @reserve_end_at_timestamp = @reservation.reserve_end_at.strftime("%a, %d %b %Y %H:%M:%S")

      @cal_obj_wo_actual_end = @reservation.as_calendar_object

      @reservation.actual_start_at = 1.minute.from_now
      @reservation.actual_end_at = 5.minutes.from_now

      @cal_obj_w_actual_end = @reservation.as_calendar_object

      @actual_start_at_timestamp = @reservation.actual_start_at.strftime("%a, %d %b %Y %H:%M:%S")
      @actual_end_at_timestamp = @reservation.actual_end_at.strftime("%a, %d %b %Y %H:%M:%S")

      assert @reservation.reserve_start_at != @reservation.actual_start_at
      assert @reservation.reserve_end_at != @reservation.actual_end_at
    end

    it "should have start set to reserve_start_at timestamp if no actual" do
      expect(@cal_obj_wo_actual_end["start"]).to eq(@reserve_start_at_timestamp)
    end
    it "should have end set to reserve_end_at timestamp if no actual" do
      expect(@cal_obj_wo_actual_end["end"]).to eq(@reserve_end_at_timestamp)
    end

    it "should have start set to actual timestamp" do
      expect(@cal_obj_w_actual_end["start"]).to eq(@actual_start_at_timestamp)
    end
    it "should have end set to actual_end_at timestamp" do
      expect(@cal_obj_w_actual_end["end"]).to eq(@actual_end_at_timestamp)
    end

    it "should include the instrument name" do
      expect(@cal_obj_w_actual_end["product"]).to eq(@instrument.name)
    end
  end

  context "for_date" do
    before :each do
      @rule.destroy
      @instrument.update_attribute :reserve_interval, 15
      @instrument.reload
      @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule).merge(start_hour: 0, end_hour: 24))

      @spans_day_reservation = instrument.reservations.create!(reserve_start_at: Time.current.end_of_day - 1.hour,
                                                               duration_mins: 120,
                                                               split_times: true)

      @today_reservation = instrument.reservations.create!(reserve_start_at: Time.current.beginning_of_day + 8.hours,
                                                           duration_mins: 120,
                                                           split_times: true)

      @yeserday_reservation = instrument.reservations.create!(reserve_start_at: Time.current.beginning_of_day - 16.hours,
                                                              duration_mins: 120,
                                                              split_times: true)

      @tomorrow_reservation = instrument.reservations.create!(reserve_start_at: Time.current.end_of_day + 8.hours,
                                                              duration_mins: 120,
                                                              split_times: true)
    end

    it "returns reservations from a single day" do
      expect(Reservation.for_date(Time.zone.now - 1.day))
        .to contain_all [@yeserday_reservation]
    end

    it "returns a reservation that spans days when looking up the earlier date" do
      expect(Reservation.for_date(Time.zone.now))
        .to contain_all [@today_reservation, @spans_day_reservation]
    end

    it "returns a reservation that spans days when looking up the later date" do
      expect(Reservation.for_date(Time.zone.now + 1.day))
        .to contain_all [@tomorrow_reservation, @spans_day_reservation]
    end
  end

  describe "finding reservations in a given range" do
    let(:this_sunday) { Time.zone.at 1_361_685_600 } # Sun, 24 Feb 2013 00:00:00
    let(:next_sunday) { Time.zone.at 1_362_290_400 } # Sun, 03 Mar 2013 00:00:00

    let!(:instrument) do
      @instrument.update_attributes max_reserve_mins: nil, reserve_interval: 15
      @instrument.reload
    end

    let!(:rule) do
      @rule.destroy
      attrs = FactoryGirl.attributes_for :schedule_rule, start_hour: 0, end_hour: 24
      @instrument.schedule_rules.create attrs
    end

    let!(:weekend_res) do
      @instrument.reservations.create!(
        reserve_start_at: Time.zone.parse("2013-02-22 17:00:00"),
        duration_mins: 4080,
        split_times: true,
      )
    end

    let!(:monday_res) do
      @instrument.reservations.create!(
        reserve_start_at: Time.zone.parse("2013-02-25 13:00:00"),
        duration_mins: 180,
        split_times: true,
      )
    end

    let!(:next_weekend_res) do
      @instrument.reservations.create!(
        reserve_start_at: next_sunday - 7.hours,
        duration_mins: 600,
        split_times: true,
      )
    end

    let!(:next_monday_res) do
      @instrument.reservations.create!(
        reserve_start_at: next_sunday + 7.hours,
        duration_mins: 180,
        split_times: true,
      )
    end

    let!(:prior_friday_res) do
      @instrument.reservations.create!(
        reserve_start_at: weekend_res.reserve_start_at - 7.hours,
        duration_mins: 180,
        split_times: true,
      )
    end

    it "should find the weekend reservation" do
      reservations = Reservation.in_range this_sunday, next_sunday
      expect(reservations).to include weekend_res
      expect(reservations).to include monday_res
      expect(reservations).to include next_weekend_res
      expect(reservations).not_to include prior_friday_res
      expect(reservations).not_to include next_monday_res
    end
  end

  describe "#extendable?" do
    subject(:reservation) do
      FactoryGirl.build(:purchased_reservation,
                        :running,
                        product: instrument)
    end

    before do
      reservation.save!
      reservation.order.update_attribute(:state, "purchased")
    end

    it "has an available next duration" do
      expect(reservation).to be_extendable
    end

    context "with another reservation following" do
      let(:other_reservation) do
        FactoryGirl.build(:purchased_reservation,
                          reserve_start_at: reservation.reserve_end_at,
                          reserve_end_at: reservation.reserve_end_at + 1.hour,
                          product: reservation.product)
      end

      before do
        other_reservation.save!
        other_reservation.order.update_attribute(:state, "purchased")
      end

      it "has no available next duration" do
        expect(reservation).not_to be_extendable
      end
    end

    context "with a reservation at the end of a day" do
      before do
        reservation.product.schedule_rules[0].tap do |rule|
          reservation.reserve_start_at = reservation.reserve_start_at.change(hour: rule.end_hour - 1, min: rule.end_min)
          reservation.reserve_end_at = reservation.reserve_end_at.change(hour: rule.end_hour, min: rule.end_min)
          reservation.save!
        end
      end

      it "has no available next duration" do
        expect(reservation).not_to be_extendable
      end
    end

    context "when the instrument has cutoff_hours set" do
      before do
        instrument.update_attributes(cutoff_hours: 2, max_reserve_mins: 240)
      end

      context "when the reservation end_time is within cutoff_hours from now" do

        context "when the reservation is started" do
          it { expect(reservation).to be_extendable }
        end
      end

      context "when the reservation end_time is past cutoff_hours from now" do
        before do
          reservation.update_attributes(reserve_end_at: reservation.reserve_start_at + 3.hours)
        end

        context "when the reservation is started" do
          it { expect(reservation).to be_extendable }
        end
      end

      context "with another reservation following" do
        let(:other_reservation) do
          FactoryGirl.build(:purchased_reservation,
                            reserve_start_at: reservation.reserve_end_at,
                            reserve_end_at: reservation.reserve_end_at + 1.hour,
                            product: reservation.product)
        end

        before do
          other_reservation.save!
          other_reservation.order.update_attribute(:state, "purchased")
        end

        it "has no available next duration" do
          expect(reservation).not_to be_extendable
        end
      end
    end
  end

  describe "#duration_mins" do
    context "with no actual start time" do
      it "calcuates duration using reservation start time" do
        expect(reservation.duration_mins).to eq(60)
      end
    end
  end
end
