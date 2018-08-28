# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentOfflineReservationCanceler do
  subject { described_class.new }

  let(:order_detail) { reservation.order_detail }
  let(:price_policy) { instrument.price_policies.first }
  let(:stub_mailer) { double(ActionMailer::MessageDelivery) }
  let(:user) { order_detail.user }

  describe "#cancel!" do
    context "when the instrument is offline" do
      let!(:instrument) { FactoryBot.create(:setup_instrument, :offline) }

      context "when a reservation starting now exists" do
        let!(:reservation) do
          FactoryBot.create(:purchased_reservation,
                            product: instrument,
                            reserve_start_at: Time.current)
        end

        before(:each) do
          allow(OfflineCancellationMailer)
            .to receive(:send_notification) { stub_mailer }
          allow(stub_mailer).to receive(:deliver_later)
          subject.cancel!
        end

        it "cancels the reservation", :aggregate_failures do
          expect(reservation.reload).to be_canceled
          expect(order_detail.reload.canceled_reason)
            .to eq("The instrument was offline")
        end

        context "when the instrument normally imposes a cancellation cost" do
          before { price_policy.update(cancellation_cost: 10) }

          it "does not charge the user" do
            expect(order_detail.reload.actual_cost).to be_blank
          end
        end

        it "sends a cancellation notification to the user" do
          expect(OfflineCancellationMailer)
            .to have_received(:send_notification)
            .with(reservation)
          expect(stub_mailer).to have_received(:deliver_later)
        end
      end
    end
  end
end
