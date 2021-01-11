require "rails_helper"

RSpec.describe NucoreKfs::CollectorExport, type: :service do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:kfs_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "KFS-7777777-4444") }
  let(:uch_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "UCH-7777777-4444") }


  context "in open journal with KFS account" do
    let(:exporter) { described_class.new }
    let(:journal) { FactoryBot.create(:journal, facility: facility) }
    let(:order_detail) { place_and_complete_item_order(user, facility, kfs_account, true) }
    let(:journal_rows) {
      journal.create_journal_rows!([order_detail])
      journal.journal_rows
    }

    context "collector" do

      it "handles invalid journal rows" do
        journal_row = double
        allow(journal_row).to receive(:order_detail).and_return(nil)
        
        expect{exporter.create_collector_transactions_from_journal_rows(journal_rows)}.to_not raise_error
      end

      it "can build transactions from multiple journal rows" do
        expect(exporter.create_collector_transactions_from_journal_rows(journal_rows)).to be_valid
      end

      it "has correct number of transactions" do
        transactions = exporter.create_collector_transactions_from_journal_rows(journal_rows)

        expect(transactions.length()).to eq(journal_rows.length())
      end

      it "can export journal" do
        expect(exporter.generate_export_file_new(journal_rows)).to be_valid
      end
    end

    context "exported collector" do

      it "has correct header format" do
        header = exporter.generate_export_header()

        expect(header.lines.count).to eq(1)
        expect(header.size).to eq(172)
        expect(header[10..14].blank?).to be true
        expect(header[170..171].blank?).to be true
      end

      it "has correct number of general ledger entries" do
        transactions = exporter.create_collector_transactions_from_journal_rows(journal_rows)
        transaction_entries = exporter.create_general_ledger_entries_from_transactions(transactions)

        expect(transaction_entries[:records]).to eq(transactions.length() * 2)
      end
  
      it "has correct general ledger entry format for each transaction" do
        transactions = exporter.create_collector_transactions_from_journal_rows(journal_rows)
        transactions.each do |transaction|
          expect(transaction.lines.count).to eq(1)
          expect(transaction.size).to eq(189)

          expect(transaction[7..11].blank?).to be true
          expect(transaction[16..18].blank?).to be true
          expect(transaction[16..18].blank?).to be true
          expect(transaction[44..48].blank?).to be true
          expect(transaction[89].blank?).to be true
          expect(transaction[140..149].blank?).to be true
          expect(transaction[158..188].blank?).to be true
        end
      end

      it "has valid trailer fields" do
        transactions = exporter.create_collector_transactions_from_journal_rows(journal_rows)
        transaction_entries = exporter.create_general_ledger_entries_from_transactions(transactions)

        expect(transaction_entries[:records]).to be > 0
        expect(transaction_entries[:file_amt]).to be > 0
      end
  
      it "has correct trailer format" do
        records = 2
        file_amt = 200
        trailer_record = exporter.generate_trailer_record(records, file_amt)

        expect(trailer_record.lines.count).to eq(1)
        expect(trailer_record.size).to eq(112)

        expect(trailer_record[0..24].blank?).to be true
        expect(trailer_record[27..45].blank?).to be true
        expect(trailer_record[51..91].blank?).to be true
      end
    end
  end
end

