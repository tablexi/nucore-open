require "rails_helper"

RSpec.describe ExportRawReportMailer do
  context ".raw_report_email" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:report) { double Reports::ExportRaw, filename: "test.csv", to_csv: "1,2,3\n", description: "test" }

    before :each do
      ExportRawReportMailer.raw_report_email("recipient@example.net", report).deliver_now
    end

    context "mail headers" do
      it "has the correct recipient" do
        expect(email.to.first).to eq "recipient@example.net"
      end

      it "has the correct sender" do
        expect(email.from.first).to eq Settings.email.from
      end
    end

    context "mail body" do
      it "has an attachment" do
        expect(email.attachments.count).to eq 1
      end
    end
  end
end
