require "rails_helper"

RSpec.describe JournalRowUpdater, type: :service do

  let(:updater) { described_class.new(order_detail) }
  let(:order_detail) { build_stubbed(:order_detail, account: account, journal_rows: journal_rows) }
  let(:account) { NufsAccount.new }
  let(:journal_rows) { build_stubbed_list(:journal_row, 1) }

  describe "initialize" do
    it "assigns order_detail" do
      expect(updater.order_detail).to eq(order_detail)
    end

    it "assigns journal_rows" do
      expect(updater.journal_rows).to eq(journal_rows)
    end
  end

  describe "when the order detail is on a failed journal" do
    let(:user) { FactoryGirl.create(:user) }
    let(:facility) { FactoryGirl.create(:setup_facility) }
    let(:account) { FactoryGirl.create(:setup_account, owner: user) }
    # Original costs: actual: 20, subsidy: 10
    let(:order_detail) { place_and_complete_item_order(user, facility, account, true) }
    let(:journal) { FactoryGirl.create(:journal, is_successful: false, facility: facility) }

    before do
      journal.create_journal_rows!([order_detail])
      OrderDetail.where(journal_id: journal.id).update_all(journal_id: nil)
    end

    describe "and I update the pricing" do
      before do
        order_detail.reload
        allow(order_detail.account).to receive(:recreate_journal_rows_on_order_detail_update?).and_return true
        order_detail.update_attributes(actual_cost: 20.37)
      end

      it "updates the order detail" do
        expect(order_detail.reload.actual_cost).to eq(20.37)
        expect(order_detail.total).to eq(10.37)
      end

      it "updates the journal row" do
        expect(JournalRow.find_by_order_detail_id(order_detail.id).amount).to eq(10.37)
      end
    end
  end

end
