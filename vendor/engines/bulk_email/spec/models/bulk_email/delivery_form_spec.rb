require "rails_helper"

RSpec.describe BulkEmail::DeliveryForm do
  subject(:form) { described_class.new(facility) }
  let(:recipients) { FactoryGirl.create_list(:user, 3) }
  let(:facility) { FactoryGirl.build_stubbed(:facility) }

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
    end

    it "queues mail to all recipients" do
      form.deliver_all
    end
  end
end
