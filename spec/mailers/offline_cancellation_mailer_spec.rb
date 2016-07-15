require "rails_helper"

RSpec.describe OfflineCancellationMailer do
  let(:email) { ActionMailer::Base.deliveries.last }

  describe ".send_notification" do
    before(:each) do
      allow(reservation).to receive(:user) { user }
      allow(reservation).to receive(:product) { instrument }
      allow(Reservation).to receive(:find).with(reservation.id) { reservation }
      described_class.send_notification(reservation.id).deliver_now
    end

    let(:instrument) { FactoryGirl.create(:setup_instrument) }
    let(:reservation) { FactoryGirl.build_stubbed(:reservation) }
    let(:user) { FactoryGirl.build_stubbed(:user) }

    it "generates an offline cancellation notification", :aggregate_failures do
      expect(email.to).to eq [user.email]

      # TODO: Email content is TBD and therefore subject to change:
      expect(email.subject)
        .to eq("Your reservation for #{instrument} has been canceled")
      expect(email.html_part.to_s)
        .to include("#{instrument} is unavailable")
      expect(email.text_part.to_s)
        .to include("#{instrument} is unavailable")
    end
  end
end
