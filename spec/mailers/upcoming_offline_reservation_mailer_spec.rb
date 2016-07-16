require "rails_helper"

RSpec.describe UpcomingOfflineReservationMailer do
  let(:email) { ActionMailer::Base.deliveries.last }

  describe ".generate_mail" do
    let(:instrument) { FactoryGirl.create(:setup_instrument) }
    let(:reservation) { FactoryGirl.build_stubbed(:reservation) }
    let(:user) { FactoryGirl.build_stubbed(:user) }

    before(:each) do
      allow(reservation).to receive(:user) { user }
      allow(reservation).to receive(:product) { instrument }
      described_class.generate_mail(reservation).deliver_now
    end

    it "generates an upcoming offline reservation notification", :aggregate_failures do
      expect(email.to).to eq [user.email]

      # TODO: Email content is TBD and therefore subject to change:
      expect(email.subject)
        .to eq("Regarding your upcoming reservation for #{instrument}")
      expect(email.html_part.to_s).to include("#{instrument}, is down")
      expect(email.text_part.to_s).to include("#{instrument}, is down")
    end
  end
end
