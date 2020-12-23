
require "rails_helper"

RSpec.describe NucoreKfs::CollectorExport do
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:kfs_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "KFS-7777777-4444") }
  let(:uch_account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, account_number: "UCH-7777777-4444") }

  context "in open journal with KFS account" do
    let(:order_detail) { place_and_complete_item_order(user, facility, account, true) }
    let(:journal) { FactoryBot.create(:journal, facility: facility) }

    it "gets the expected fields for accounts" do
      exporter = NucoreKfs::CollectorExport.new

      journal.create_journal_rows!([order_detail])
      puts("journal amount = #{journal.amount}")
      j_rows = journal.journal_rows
      row = journal.journal_rows.first

      # puts("j_rows = #{row.attributes}")
      # puts("account = #{account.attributes}")
      # puts(" order_detail_row.account = #{roworder_detail.account.attributes}")

      debit_account = exporter.get_debit_account(row.order_detail)
      puts("debit_account = #{debit_account}")

      expect(debit_account).to eq("KFS-7777777-4444")
    end
  end

 

end
