# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation do
  context "started reservation completed by cron job" do
    subject do
      res = FactoryBot.create :purchased_reservation,
                              reserve_start_at: Time.zone.parse("#{Date.today} 10:00:00") - 2.days,
                              reserve_end_at: Time.zone.parse("#{Date.today} 10:00:00") - 2.days + 1.hour,
                              actual_start_at: Time.zone.parse("#{Date.today} 10:00:00") - 2.days

      # needs to have a relay
      res.product.relay = FactoryBot.create(:relay_dummy, instrument: res.product)
      res.order_detail.change_status!(OrderStatus.find_by(name: "Complete"))
      res
    end

    # Confirming setup
    it { is_expected.not_to be_has_actuals }
    it { is_expected.to be_complete }

    it "should have a relay" do
      expect(subject.product.relay).to be_a RelayDummy
    end

    describe "#actual_end_at" do
      subject { super().actual_end_at }
      it { is_expected.to be_nil }
    end

    describe "#actual_start_at" do
      subject { super().actual_start_at }
      it { is_expected.to be }
    end

    it { is_expected.not_to be_can_switch_instrument_on }
    it { is_expected.not_to be_can_switch_instrument_off }
  end

  context "#other_reservations_using_relay" do
    let!(:reservation_done) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }

    context "with no other running reservations" do
      it "returns nothing" do
        expect(reservation_done.other_reservations_using_relay).to be_empty
      end
    end

    context "with one other running reservation" do
      let!(:reservation_running) { create(:purchased_reservation, :running, product: reservation_done.product) }

      it "returns the running reservation" do
        expect(reservation_done.other_reservations_using_relay).to match_array([reservation_running])
      end
    end

    context "with a running reservation for another product using the same schedule" do
      let!(:product_shared) { create(:setup_instrument, schedule: reservation_done.product.schedule) }
      let!(:reservation_shared_running) { create(:purchased_reservation, :running, product: product_shared) }

      it "returns the running reservation" do
        expect(reservation_done.other_reservations_using_relay).to match_array([reservation_shared_running])
      end
    end

    context "with a running admin reservation" do
      let!(:reservation_admin_running) { create(:reservation, :running, product: reservation_done.product) }

      it "returns the running reservation" do
        expect(reservation_done.other_reservations_using_relay).to match_array([reservation_admin_running])
      end
    end

    context "with completed reservations" do
      let!(:reservation_done_2) { create(:purchased_reservation, :later_yesterday, product: reservation_done.product) }

      it "returns nothing" do
        expect(reservation_done.other_reservations_using_relay).to be_empty
      end
    end

    context "with one other running reservation is canceled" do
      let!(:canceled_reservation) { create(:purchased_reservation, product: reservation_done.product) }

      before do
        canceled_reservation.order_detail.cancel_reservation(canceled_reservation.user)
      end

      it "does not return canceled reservation" do
        expect(reservation_done.other_reservations_using_relay).to match_array([])
      end
    end
  end
end
