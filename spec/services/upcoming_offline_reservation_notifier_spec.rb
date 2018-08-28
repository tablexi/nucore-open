# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpcomingOfflineReservationNotifier do
  subject { described_class.new }

  describe "#notify", :time_travel do
    let(:now) { Date.today.beginning_of_day + 30.minutes }

    context "when an instrument is offline" do
      let!(:instrument) { FactoryBot.create(:setup_instrument, :offline) }

      context "and a purchased reservation exists for it" do
        let!(:reservation) do
          FactoryBot.create(:purchased_reservation,
                            product: instrument,
                            reserve_start_at: now + 10.hours,
                            reserve_end_at: now + 11.hours)
        end
        let(:stub_delivery) { double(ActionMailer::MessageDelivery) }
        let(:user) { reservation.user }

        before(:each) do
          allow(UpcomingOfflineReservationMailer)
            .to receive(:send_offline_instrument_warning) { stub_delivery }
          allow(stub_delivery).to receive(:deliver_later)
          subject.notify
        end

        it "creates a notification for the reservation's user" do
          expect(UpcomingOfflineReservationMailer)
            .to have_received(:send_offline_instrument_warning)
            .with(reservation)
          expect(stub_delivery).to have_received(:deliver_later)
        end
      end
    end
  end
end
