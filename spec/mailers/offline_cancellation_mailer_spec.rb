require "rails_helper"

RSpec.describe OfflineCancellationMailer do
  let(:email) { ActionMailer::Base.deliveries.last }

  describe ".send_notification" do
    before(:each) do
      allow(reservation).to receive(:user) { user }
      allow(reservation).to receive(:product) { instrument }
      allow(reservation).to receive(:order) { order }
      allow(reservation).to receive(:order_detail) { order_detail }
      described_class.send_notification(reservation).deliver_now
    end

    let(:instrument) { FactoryGirl.create(:setup_instrument) }
    let(:order) { FactoryGirl.build_stubbed(:order) }
    let(:order_detail) { FactoryGirl.build_stubbed(:order_detail) }
    let(:reservation) { FactoryGirl.build_stubbed(:reservation) }
    let(:user) { FactoryGirl.build_stubbed(:user) }

    it "generates an offline cancellation notification", :aggregate_failures do
      expect(email.to).to eq [user.email]

      expect(email.subject)
        .to eq("Your reservation for #{instrument} has been canceled")
      expect(email.html_part.to_s).to match(/#{instrument}\b.+is down/m)
      expect(email.text_part.to_s).to match(/#{instrument}\b.+is down/m)
    end
  end
end
