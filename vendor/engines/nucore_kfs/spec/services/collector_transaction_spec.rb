require "rails_helper"
require_relative "../kfs_spec_helper.rb"

RSpec.describe NucoreKfs::CollectorTransaction, type: :service do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_kfs_facility) }
  let(:kfs_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "KFS-7777777-4444") }
  let(:uch_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "UCH-7777777-4444") }
  
  context "in open journal with KFS account" do
    let(:transaction) { described_class.new(journal_rows.first) }
    let(:journal) { FactoryBot.create(:kfs_journal, facility: facility) }
    let(:order_detail) { place_and_complete_kfs_item_order(user, facility, kfs_account, true) }
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
      expect(transaction).to_not be_nil
    end

    it "has expected debit/credit code" do
      expect(transaction.create_credit_row_string()[117]).to eq("C")
      expect(transaction.create_debit_row_string()[117]).to eq("D")
    end

    it "has correct export format" do
      row = transaction.create_credit_row_string()

      expect(row.lines.count).to eq(1)
      expect(row.size).to eq(187)

      expect(row[13..17].blank?).to be true
      expect(row[22..24].blank?).to be true
      expect(row[27..30].blank?).to be true
      expect(row[51..54].blank?).to be true
      expect(row[91].blank?).to be true
      expect(row[132..140].blank?).to be true
      expect(row[157..187].blank?).to be true
    end
  end

  context "in open journal with UCH account" do
    let(:transaction) { described_class.new(journal_rows.first) }
    let(:journal) { FactoryBot.create(:kfs_journal, facility: facility) }
    let(:order_detail) { place_and_complete_kfs_item_order(user, facility, kfs_account, true) }
    let(:journal_rows) {
        journal.create_journal_rows!([order_detail])
        journal.journal_rows
    }

    it "can get expected account number" do
      debit_account = transaction.get_debit_account(journal_rows.first.order_detail)

      expect(debit_account).to eq("KFS-7777777-4444")
    end

    it "can convert journal row to transaction" do
      expect(transaction).to_not be_nil
    end

    it "has expected debit/credit code" do
      expect(transaction.create_credit_row_string()[117]).to eq("C")
      expect(transaction.create_debit_row_string()[117]).to eq("D")
    end

    it "has correct export format" do
      row = transaction.create_credit_row_string()

      expect(row.lines.count).to eq(1)
      expect(row.size).to eq(187)

      expect(row[13..17].blank?).to be true
      expect(row[22..24].blank?).to be true
      expect(row[27..30].blank?).to be true
      expect(row[51..54].blank?).to be true
      expect(row[91].blank?).to be true
      expect(row[132..140].blank?).to be true
      expect(row[157..187].blank?).to be true
    end
  end
end
