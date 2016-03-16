require "rails_helper"

RSpec.describe Reports::ExportRaw do

  let(:account) do
    FactoryGirl.build(:split_account, without_splits: true, account_users_attributes: account_users_attributes_hash(user: user)).tap do |account|
      account.splits << build(:split, percent: 50, extra_penny: true, subaccount: subaccounts[0], parent_split_account: account)
      account.splits << build(:split, percent: 50, extra_penny: false, subaccount: subaccounts[1], parent_split_account: account)
      account.save
    end
  end

  let(:subaccounts) { FactoryGirl.create_list(:setup_account, 2) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:item) { FactoryGirl.create(:setup_item, facility: facility) }
  let(:order_detail) do
    order_detail = place_product_order(user, facility, item, account)

    # prevent the order_detail from assigning different actual_cost and actual_subsidy
    allow(order_detail).to receive(:assign_actual_price).and_return(nil)

    order_detail.quantity = 3
    order_detail.actual_subsidy = BigDecimal("9.99")
    order_detail.actual_cost = BigDecimal("19.99")
    order_detail.estimated_subsidy = BigDecimal("29.99")
    order_detail.estimated_cost = BigDecimal("39.99")
    order_detail.save!
    order_detail
  end

  let(:report) { described_class.new(**report_args) }
  let(:report_args) do
    {
      action_name: "general",
      facility: facility,
      order_status_ids: [order_detail.order_status_id],
      headers: headers,
      date_end: 1.day.from_now,
      date_start: 1.day.ago,
      date_range_field: "ordered_at"
    }
  end

  let(:headers) { I18n.t("controllers.general_reports.headers.data") }
  let(:lines) { report.to_csv.split("\n") }
  let(:cells) { lines.map{ |line| line.split(",") } }
  let(:cells_without_headers) { cells[1..-1] }
  let(:column_values) { cells_without_headers.map { |line| line[column_index] } }

  it "exports correct number of line items" do
    expect(lines.length).to eq(3)
  end

  it "returns headers as first line item" do
    expect(lines.first).to eq(headers.join(","))
  end

  context "for quantity column values" do
    let(:column_index) { headers.index("Quantity") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits quantity" do
      expect(column_values).to contain_exactly("1.5", "1.5")
    end
  end

  context "for actual subsidy column values" do
    let(:column_index) { headers.index("Actual Subsidy") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits actual_subsidy" do
      expect(column_values).to contain_exactly("$4.99", "$5.00")
    end
  end

  context "for actual cost column values" do
    let(:column_index) { headers.index("Actual Cost") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits actual_subsidy" do
      expect(column_values).to contain_exactly("$9.99", "$10.00")
    end
  end

  context "for estimated subsidy column values" do
    let(:column_index) { headers.index("Estimated Subsidy") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits actual_subsidy" do
      expect(column_values).to contain_exactly("$14.99", "$15.00")
    end
  end

  context "for estimated subsidy column values" do
    let(:column_index) { headers.index("Estimated Cost") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits actual_subsidy" do
      expect(column_values).to contain_exactly("$19.99", "$20.00")
    end
  end

end
