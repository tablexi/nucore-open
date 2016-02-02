require "rails_helper"

RSpec.describe JournalRowBuilder, type: :service do

  let(:builder) { described_class.new(order_details, journal) }
  let(:order_details) { build_stubbed_list(:order_detail, 2) }
  let(:journal) { build_stubbed(:journal) }

  describe ".new" do
    it "assigns journal" do
      expect(builder.journal).to eq(journal)
    end

    it "assigns order_details" do
      expect(builder.order_details).to eq(order_details)
    end

    it "assigns empty errors" do
      expect(builder.errors).to eq([])
    end

    it "assigns empty journal_rows" do
      expect(builder.journal_rows).to eq([])
    end

    it "assigns empty product_recharges" do
      expect(builder.product_recharges).to eq({})
    end

    context "when recharge_accounts enabled", feature_setting: {recharge_accounts: true} do
      it "assigns recharge_enabled" do
        expect(builder.recharge_enabled).to eq(true)
      end
    end

    context "when recharge_accounts disabled", feature_setting: {recharge_accounts: false} do
      it "assigns recharge_enabled" do
        expect(builder.recharge_enabled).to eq(false)
      end
    end
  end

  describe ".build" do

    let(:journal) do
      build(:journal,
        facility: facility,
        created_by: 1,
        journal_date: journal_date,
      )
    end

    let(:facility) { create(:facility) }
    let(:facility_account) { facility.facility_accounts.create(attributes_for(:facility_account)) }
    let(:journal_date) { Time.zone.now }
    let(:order) { create(:purchased_order, product: product) }
    let(:order_details) { order.order_details }
    let(:product) { create(:setup_item, facility: facility, facility_account: facility_account) }

    before do
      order_details.each(&:to_complete!)
    end

    context "when recharge_accounts enabled", feature_setting: {recharge_accounts: true} do
      it "builds two journal_rows for each order_detail" do
        expect(builder.build.journal_rows.size).to eq(order_details.size*2)
      end

      it "builds a product_recharge for each order_detail" do
        expect(builder.build.product_recharges.size).to eq(order_details.size)
      end
    end

    context "when recharge_accounts disabled", feature_setting: {recharge_accounts: false} do
      it "builds a journal_row for each order_detail" do
        expect(builder.build.journal_rows.size).to eq(order_details.size)
      end

      it "does not have product_recharges" do
        expect(builder.build.product_recharges).to be_empty
      end

    end

  end
end
