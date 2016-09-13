require "rails_helper"

RSpec.describe BulkEmail::Mailer do
  describe ".mail" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:recipient) { FactoryGirl.build_stubbed(:user) }
    let(:subject_line) { "Subject Line" }
    let(:custom_message) { "Custom message" }
    let(:facility) { FactoryGirl.build_stubbed(:facility) }

    before(:each) do
      described_class
        .send_mail(
          recipient: recipient,
          subject: subject_line,
          facility: facility,
          custom_message: custom_message,
        )
        .deliver_now
    end

    it { expect(email.to).to eq [recipient.email] }
    it { expect(email.subject).to eq subject_line }
    it { expect(email.html_part.to_s).to include(custom_message) }
    it { expect(email.text_part.to_s).to include(custom_message) }
  end
end
