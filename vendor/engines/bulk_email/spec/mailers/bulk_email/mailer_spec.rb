require "rails_helper"

RSpec.describe BulkEmail::Mailer do
  describe ".mail" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:recipient) { FactoryGirl.build_stubbed(:user) }
    let(:custom_subject) { "Custom subject" }
    let(:custom_message) { "Custom message" }

    before(:each) do
      described_class
        .send_mail(
          custom_message: custom_message,
          custom_subject: custom_subject,
          recipient: recipient,
        )
        .deliver_now
    end

    it { expect(email.to).to eq [recipient.email] }
    it { expect(email.subject).to eq(custom_subject) }
    it { expect(email.html_part.to_s).to include(custom_message) }
    it { expect(email.text_part.to_s).to include(custom_message) }
  end
end
