require "spec_helper"

describe AccountTransactionReportMailer do
  context '#csv_report_email' do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:report) { double Reports::AccountTransactionsReport, to_csv: "1,2,3\n", description: 'test' }

    before :each do
      AccountTransactionReportMailer.csv_report_email('recipient@example.net', [1,2,3], :statement_date).deliver
    end

    context 'mail headers' do
      it 'has the correct recipient' do
        expect(email.to.first).to eq 'recipient@example.net'
      end

      it 'has the correct sender' do
        expect(email.from.first).to eq Settings.email.from
      end
    end

    context 'mail body' do
      it 'has an attachment' do
        expect(email.attachments.count).to eq 1
      end
    end
  end
end
