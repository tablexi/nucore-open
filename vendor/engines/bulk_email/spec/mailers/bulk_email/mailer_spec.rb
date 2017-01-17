require "rails_helper"

RSpec.describe BulkEmail::Mailer do
  describe ".mail" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:recipient) { FactoryGirl.build_stubbed(:user) }
    let(:custom_subject) { "Custom subject" }
    let(:body) { "Custom message" }
    let(:reply_to) { "reply@example.com" }

    context "with reply_to set" do
      before(:each) do
        described_class
          .send_mail(body: body, subject: custom_subject, recipient: recipient, reply_to: reply_to)
          .deliver_now
      end

      it { expect(email.to).to eq [recipient.email] }
      it { expect(email.subject).to eq(custom_subject) }
      it { expect(email.reply_to).to eq [reply_to] }
      it { expect(email.html_part.to_s).to include(body) }
      it { expect(email.text_part.to_s).to include(body) }
    end

    context "without reply_to set" do
      before(:each) do
        described_class
          .send_mail(body: body, subject: custom_subject, recipient: recipient)
          .deliver_now
      end

      it { expect(email.reply_to).to be_nil }
    end
  end
end
