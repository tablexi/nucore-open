# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderUncanceler do
  let(:cancel_status) { OrderStatus.canceled }
  let(:uncanceler) { OrderUncanceler.new }

  context "with an item" do
    let(:item) { FactoryBot.create(:setup_item) }
    let(:order) { FactoryBot.create(:purchased_order, product: item) }
    let(:order_detail) { order.order_details.first }

    it "should not uncancel a not-canceled order" do
      uncanceler.uncancel_to_complete(order_detail)
      expect(order_detail).not_to be_changed
      expect(order_detail).not_to be_canceled
    end

    context "with a canceled order" do
      before :each do
        order_detail.update_order_status!(order.user, cancel_status)
        expect(order_detail).to be_canceled
        uncanceler.uncancel_to_complete(order_detail)
      end

      it "should uncancel" do
        expect(order_detail).to be_complete
      end

      it "should have a price" do
        expect(order_detail.actual_cost).to be > 0
      end

      it "should have a price policy" do
        expect(order_detail.price_policy).to be
      end
    end
  end

  context "with a reservation" do
    let(:reservation) { FactoryBot.create(:purchased_reservation, reserve_start_at: 1.day.ago, reserve_end_at: 23.hours.ago, reserved_by_admin: true) }
    let(:order_detail) { reservation.order_detail }
    before :each do
      order_detail.product.price_policies.update_all(start_date: 7.days.ago)
      reservation.order_detail.backdate_to_complete!(Time.zone.now)
      expect(order_detail).to be_complete
    end

    context "and the reservation is canceled" do
      before :each do
        order_detail.update_order_status!(order_detail.user, cancel_status, admin: true)
        expect(order_detail).to be_canceled
        uncanceler.uncancel_to_complete(order_detail)
      end

      it "should make complete" do
        expect(order_detail).to be_complete
      end

      it "should have a price" do
        expect(order_detail.actual_cost).to be > 0
      end

      it "should have a price policy" do
        expect(order_detail.price_policy).to be
      end

      it "should set the fulfilled date to the reservation end time" do
        expect(order_detail.fulfilled_at).to eq(reservation.reserve_end_at)
      end

      it "should set the actuals off the reservation" do
        expect(reservation.reload.actual_start_at).to eq(reservation.reserve_start_at)
        expect(reservation.reload.actual_end_at).to eq(reservation.reserve_end_at)
      end
    end
  end
end
