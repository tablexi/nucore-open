require "rails_helper"

RSpec.describe InstrumentOfflineReservationCanceler do
  subject { described_class.new }

  let(:order_detail) { reservation.order_detail }
  let(:price_policy) { instrument.price_policies.first }
  let(:user) { order_detail.user }

  describe "#cancel!" do
    shared_context "the instrument is offline" do
      context "when a reservation starting now exists" do
        let!(:reservation) do
          FactoryGirl.create(:purchased_reservation,
                             product: instrument,
                             reserve_start_at: Time.current)
        end

        before(:each) do
          allow(Notifier).to receive(:delay) { Notifier }
          allow(Notifier).to receive(:offline_cancellation_notification)
          subject.cancel!
        end

        it "cancels the reservation", :aggregate_failures do
          expect(reservation.reload).to be_canceled
          expect(reservation.canceled_reason)
            .to eq("The instrument was offline")
        end

        context "when the instrument normally imposes a cancellation cost" do
          before { price_policy.update(cancellation_cost: 10) }

          it "does not charge the user" do
            expect(order_detail.reload.actual_cost).to be_blank
          end
        end

        context "when the instrument normally imposes a reservation cost" do
          before { price_policy.update(reservation_rate: 10) }

          it "does not charge the user" do
            expect(order_detail.reload.actual_cost).to be_blank
          end
        end

        it "sends a cancellation notification to the user" do
          expect(Notifier)
            .to have_received(:offline_cancellation_notification)
            .with(reservation)
        end
      end
    end

    context "when the instrument is offline" do
      let!(:instrument) { FactoryGirl.create(:setup_instrument, :offline) }

      it_behaves_like "the instrument is offline"
    end

    context "when the instrument is online" do
      let!(:instrument) { FactoryGirl.create(:setup_instrument, schedule: nil) }

      context "but shares a schedule with an instrument that is offline" do
        let!(:offline_instrument_on_shared_schedule) do
          FactoryGirl.create(:setup_instrument,
                             :offline,
                             schedule: instrument.schedule)
        end

        it_behaves_like "the instrument is offline"
      end
    end
  end
end
