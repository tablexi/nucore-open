require "rails_helper"

RSpec.describe BulkEmail::DeliveryForm do
  subject(:form) { described_class.new(user, facility) }
  let(:facility) { FactoryGirl.create(:facility) }
  let(:recipients) { FactoryGirl.create_list(:user, 3) }
  let(:user) { FactoryGirl.create(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:custom_subject) }
    it { is_expected.to validate_presence_of(:custom_message) }
    it { is_expected.to validate_presence_of(:recipient_ids) }
  end

  describe "#deliver_all" do
    before(:each) do
      recipients.each do |recipient|
        expect(form).to receive(:deliver).with(recipient)
      end

      form.recipient_ids = recipients.map(&:id)
      form.custom_subject = "Subject line"
      form.custom_message = "Custom message"
      form.search_criteria = { this: "is", a: "test" }
    end

    let(:bulk_email_job) { BulkEmail::Job.last }

    it "queues mail to all recipients" do
      expect { form.deliver_all }.to change(BulkEmail::Job, :count).by(1)
      expect(bulk_email_job.subject).to eq(form.custom_subject)
      expect(bulk_email_job.body).to eq(form.custom_message)
      expect(bulk_email_job.recipients).to match_array(recipients.map(&:email))
      expect(bulk_email_job.search_criteria).to match(this: "is", a: "test")
    end
  end
end
