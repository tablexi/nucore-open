require "rails_helper"
require_relative "../../split_accounts_spec_helper"

RSpec.describe Reports::ExportRaw, :enable_split_accounts do
  let(:account) do
    FactoryGirl.build(:split_account, without_splits: true, account_users_attributes: account_users_attributes_hash(user: user)).tap do |account|
      account.splits << build(:split, percent: 50, apply_remainder: true, subaccount: subaccounts[0], parent_split_account: account)
      account.splits << build(:split, percent: 50, apply_remainder: false, subaccount: subaccounts[1], parent_split_account: account)
      account.save
    end
  end

  let(:subaccounts) { FactoryGirl.create_list(:setup_account, 2) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:item) { FactoryGirl.create(:setup_item, facility: facility) }
  let(:base_order_detail) { place_product_order(user, facility, item, account) }
  let(:order_detail) do
    order_detail = base_order_detail

    # prevent the order_detail from assigning different actual_cost and actual_subsidy
    allow(order_detail).to receive(:assign_actual_price).and_return(nil)

    order_detail.quantity = 1
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
      date_end: 1.day.from_now,
      date_start: 1.day.ago,
      date_range_field: "ordered_at",
    }
  end

  let(:headers) { report.column_headers }
  let(:lines) { report.to_csv.split("\n") }
  let(:cells) { lines.map { |line| line.split(",") } }
  let(:cells_without_headers) { cells[1..-1] }
  let(:column_values) { cells_without_headers.map { |line| line[column_index] } }

  it "exports correct number of line items" do
    expect(lines.length).to eq(3)
  end

  it "has all the headers headers as first line item" do
    expect(cells.first).to eq(headers)
  end

  context "for quantity column values" do
    let(:column_index) { headers.index("Quantity") }

    it "has column" do
      expect(column_index).to_not be_nil
    end

    it "splits quantity" do
      expect(column_values).to contain_exactly("0.5", "0.5")
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

  context "for split percentage" do
    let(:column_index) { headers.index("Split Percent") }

    it "has the column" do
      expect(column_index).not_to be_nil
    end

    it "has the splits" do
      expect(column_values).to eq(["50%", "50%"])
    end
  end

  describe "with a non-split account" do
    let(:account) { FactoryGirl.create(:setup_account, owner: user) }

    it "exports correct number of line items" do
      expect(lines.length).to eq(2)
    end

    context "for estimated cost column values" do
      let(:column_index) { headers.index("Estimated Cost") }

      it "has the actual_cost" do
        expect(column_values).to contain_exactly("$39.99")
      end
    end

    context "for estimated subsidy column values" do
      let(:column_index) { headers.index("Estimated Subsidy") }

      it "has the actual_cost" do
        expect(column_values).to contain_exactly("$29.99")
      end
    end

    context "for actual subsidy column values" do
      let(:column_index) { headers.index("Actual Subsidy") }

      it "has the actual_cost" do
        expect(column_values).to contain_exactly("$9.99")
      end
    end

    context "for actual cost column values" do
      let(:column_index) { headers.index("Actual Cost") }

      it "has the actual_cost" do
        expect(column_values).to contain_exactly("$19.99")
      end
    end
  end

  describe "with a reservation", :timecop_freeze do
    let(:instrument) { FactoryGirl.create(:setup_instrument, :always_available, facility: facility) }
    let(:now) { Time.zone.parse("2016-02-01 10:30") }
    let(:reservation) do
      FactoryGirl.create(:completed_reservation,
                         product: instrument,
                         reserve_start_at: Time.zone.parse("2016-02-01 08:30"),
                         reserve_end_at: Time.zone.parse("2016-02-01 09:30"),
                         actual_start_at: Time.zone.parse("2016-02-01 08:30"),
                         actual_end_at: Time.zone.parse("2016-02-01 09:35"))
    end
    let(:user) { order_detail.user }
    let(:base_order_detail) { reservation.order_detail }

    before { order_detail.update_attributes!(account: account) }

    context "for reserve_start_at" do
      let(:column_index) { headers.index("Reservation Start Time") }

      it "always has the same value" do
        expect(column_values).to be_present
        expect(column_values).to all(eq(reservation.reserve_start_at.to_s))
      end
    end

    context "for reserve_end_at" do
      let(:column_index) { headers.index("Reservation End Time") }

      it "always has the same value" do
        expect(column_values).to be_present
        expect(column_values).to all(eq(reservation.reserve_end_at.to_s))
      end
    end

    context "for the reservation duration" do
      let(:column_index) { headers.index("Reservation Minutes") }

      it "has the splits" do
        expect(column_values).to eq(%w(30.0 30.0))
      end
    end

    context "for actual_start_at" do
      let(:column_index) { headers.index("Actual Start Time") }

      it "always has the same value" do
        expect(column_values).to be_present
        expect(column_values).to all(eq(reservation.actual_start_at.to_s))
      end
    end

    context "for actual_end_at" do
      let(:column_index) { headers.index("Actual End Time") }

      it "always has the same value" do
        expect(column_values).to be_present
        expect(column_values).to all(eq(reservation.actual_end_at.to_s))
      end
    end

    context "for the reservation duration" do
      let(:column_index) { headers.index("Actual Minutes") }

      it "has the splits" do
        expect(column_values).to eq(["32.5", "32.5"])
      end
    end

    context "for the quantity" do
      let(:column_index) { headers.index("Quantity") }

      it "has the splits" do
        expect(column_values).to eq(["0.5", "0.5"])
      end
    end
  end
end
