require "rails_helper"

RSpec.describe NucoreKfs::CollectorTransaction, type: :service do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:kfs_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "KFS-7777777-4444") }
  let(:uch_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "UCH-7777777-4444") }
  
  context "in open journal with KFS account" do
    let(:transaction) { described_class.new }
    let(:journal) { FactoryBot.create(:journal, facility: facility) }
    let(:order_detail) { place_and_complete_item_order(user, facility, kfs_account, true) }
    let(:journal_rows) {
        journal.create_journal_rows!([order_detail])
        journal.journal_rows
    }

    it "can get expected account number" do
      debit_account = transaction.get_debit_account(journal_rows.first.order_detail)

      expect(debit_account).to eq("KFS-7777777-4444")
    end

    it "handles invalid account types" do
      account = double
      order_detail = double

      allow(account).to receive(:account_number).and_return("INVALID-7777777-4444")
      allow(order_detail).to receive(:account).and_return(account)

      expect{transaction.get_debit_account(order_detail)}.to raise_error("unknown account type: INVALID-7777777-4444")
    end

    it "can convert journal row to transaction" do
      transaction.from_journal_row(journal_rows.first)

      expect(transaction).to be_valid
    end

    it "has expected debit/credit code" do
      transaction.from_journal_row(journal_rows.first)

      expect(transaction.create_credit_row_string()[119]).to eq("C")
      expect(transaction.create_debit_row_string()[119]).to eq("D")
    end

    it "has correct export format" do
      transaction.from_journal_row(journal_rows.first)
      row = transaction.create_credit_row_string()

      expect(row.lines.count).to eq(1)
      expect(row.size).to eq(189)

      expect(row[7..11].blank?).to be true
      expect(row[16..18].blank?).to be true
      expect(row[16..18].blank?).to be true
      expect(row[44..48].blank?).to be true
      expect(row[89].blank?).to be true
      expect(row[140..149].blank?).to be true
      expect(row[158..188].blank?).to be true
    end
  end
end