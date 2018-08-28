# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ExportRaw do

  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:setup_facility, name: "My Facility", abbreviation: "MF") }
  let(:account) { FactoryBot.create(:account, :with_account_owner, owner: user) }

  subject(:report) { described_class.new(**report_args) }

  let(:report_args) do
    {
      action_name: "general",
      facility_url_name: facility.url_name,
      order_status_ids: [order_detail.order_status_id],
      date_end: 1.day.from_now,
      date_start: 1.day.ago,
      date_range_field: "ordered_at",
    }
  end

  describe "for an item" do
    let(:item) { FactoryBot.create(:setup_item, facility: facility) }
    let(:order_detail) do
      place_product_order(user, facility, item, account).tap do |od|
        od.complete!
        od.manually_priced!
        od.update_attributes!(
          quantity: 3,
          actual_cost: BigDecimal("19.99"),
          actual_subsidy: BigDecimal("9.99"),
          estimated_cost: BigDecimal("39.99"),
          estimated_subsidy: BigDecimal("29.99"),
          price_change_reason: "note",
          assigned_user: user,
        )
      end
    end

    it "exports correct number of line items" do
      expect(report.to_csv.split("\n").length).to eq(2)
    end

    it "populates the report" do
      expect(report).to have_column_values(
        Facility.model_name.human => "My Facility (MF)",
        "Order" => order_detail.to_s,
        "Ordered By" => user.username,
        "First Name" => user.first_name,
        "Last Name" => user.last_name,
        "Quantity" => "3",
        "Estimated Cost" => "$39.99",
        "Estimated Subsidy" => "$29.99",
        "Estimated Total" => "$10.00",
        "Actual Cost" => "$19.99",
        "Actual Subsidy" => "$9.99",
        "Actual Total" => "$10.00",
        "Charge For" => "Quantity",
        "Assigned Staff" => user.full_name,
      )
    end

    describe "invoices" do
      it { is_expected.to have_column("Invoice Number").with_value("") }

      describe "with a statement" do
        let(:statement) { create(:statement, facility: facility, created_by: 0, account: account) }
        before { order_detail.update(statement: statement) }
        it { is_expected.to have_column("Invoice Number").with_value("#{account.id}-#{statement.id}") }
      end
    end

    context "in a cross facility context" do
      let(:report_args) do
        {
          action_name: "general",
          facility_url_name: Facility.cross_facility.url_name,
          order_status_ids: [order_detail.order_status_id],
          date_end: 1.day.from_now,
          date_start: 1.day.ago,
          date_range_field: "ordered_at",
        }
      end

      it "exports correct number of line items" do
        expect(report.to_csv.split("\n").length).to eq(2)
      end
    end

  end

  describe "with a reservation", :time_travel do
    let(:now) { Time.zone.parse("2016-02-01 10:30") }
    let(:instrument) { FactoryBot.create(:setup_instrument, :always_available, facility: facility) }
    let(:reservation) do
      FactoryBot.create(:completed_reservation,
                        product: instrument,
                        reserve_start_at: Time.zone.parse("2016-02-01 08:30"),
                        reserve_end_at: Time.zone.parse("2016-02-01 09:30"),
                        actual_start_at: Time.zone.parse("2016-02-01 08:30"),
                        actual_end_at: Time.zone.parse("2016-02-01 09:35"))
    end

    let(:user) { order_detail.user }
    let(:order_detail) do
      reservation.order_detail.tap do |od|
        od.update_attributes!(
          actual_cost: BigDecimal("19.99"),
          actual_subsidy: BigDecimal("9.99"),
          estimated_cost: BigDecimal("39.99"),
          estimated_subsidy: BigDecimal("29.99"),
        )
      end
    end

    it "populates the report" do
      expect(report).to have_column_values(
        "Reservation Start Time" => reservation.reserve_start_at.to_s,
        "Reservation End Time" => reservation.reserve_end_at.to_s,
        "Reservation Minutes" => "60",
        "Actual Start Time" => reservation.actual_start_at.to_s,
        "Actual End Time" => reservation.actual_end_at.to_s,
        "Actual Minutes" => "65",
        "Quantity" => "1",
        "Charge For" => "Reservation",
      )
    end

    context "in a cross facility context" do
      let(:report_args) do
        {
          action_name: "general",
          facility_url_name: Facility.cross_facility.url_name,
          order_status_ids: [order_detail.order_status_id],
          date_end: 1.day.from_now,
          date_start: 1.day.ago,
          date_range_field: "ordered_at",
        }
      end

      it "exports correct number of line items" do
        expect(report.to_csv.split("\n").length).to eq(2)
      end
    end
  end
end
