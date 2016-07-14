require "rails_helper"

RSpec.describe UpcomingOfflineReservationNotifier do
  subject { described_class.new }

  describe "#notify", :timecop_freeze do
    let(:now) { Date.today.beginning_of_day + 30.minutes }

    context "when an instrument is offline" do
      let!(:instrument) { FactoryGirl.create(:setup_instrument, :offline) }

      context "and a reservation exists for it" do
        let!(:reservation) do
          FactoryGirl.create(:setup_reservation,
                             product: instrument,
                             reserve_start_at: now + 10.hours,
                             reserve_end_at: now + 11.hours,
                            )
        end
        let(:user) { reservation.user }

        before(:each) do
          allow(Notifier).to receive(:upcoming_offline_reservation_notification)
          subject.notify
        end

        it "creates a notification for the reservation's user" do
          expect(Notifier)
            .to have_received(:upcoming_offline_reservation_notification)
            .with(reservation)
        end
      end
    end
  end
end
