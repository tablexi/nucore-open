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
        od.update!(
          quantity: 3,
          actual_cost: BigDecimal("19.99"),
          actual_subsidy: BigDecimal("9.99"),
          estimated_cost: BigDecimal("39.99"),
          estimated_subsidy: BigDecimal("29.99"),
          price_change_reason: "this is a reason",
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
        "Calculated Cost" => "$3.00", # Default price policy is $1/each
        "Calculated Subsidy" => "$0.00",
        "Calculated Total" => "$3.00",
        "Actual Cost" => "$19.99",
        "Actual Subsidy" => "$9.99",
        "Actual Total" => "$10.00",
        "Difference Cost" => "$16.99",
        "Difference Subsidy" => "$9.99",
        "Difference Total" => "$7.00",
        "Charge For" => "Quantity",
        "Assigned Staff" => user.full_name,
        "Bundle" => "",
        "Notices" => "",
      )
    end

    describe "invoices" do
      it { is_expected.to have_column("Invoice Number").with_value("") }

      describe "with a statement" do
        let(:statement) { create(:statement, facility: facility, created_by: 0, account: account) }
        before { order_detail.update(statement: statement) }
        it { is_expected.to have_column("Invoice Number").with_value(statement.invoice_number) }
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

  describe "for a timed service" do
    let(:timed_service) { FactoryBot.create(:setup_timed_service, facility: facility) }
    let(:order_detail) do
      place_product_order(user, facility, timed_service, account).tap do |od|
        od.complete!
        od.manually_priced!
        od.update!(
          quantity: 60,
          actual_cost: BigDecimal("199.99"),
          actual_subsidy: BigDecimal("29.99"),
          estimated_cost: BigDecimal("39.99"),
          estimated_subsidy: BigDecimal("29.99"),
          price_change_reason: "this is a reason",
          assigned_user: user,
        )
      end
    end

    it "populates the report" do
      expect(report).to have_column_values(
        Facility.model_name.human => "My Facility (MF)",
        "Order" => order_detail.to_s,
        "Ordered By" => user.username,
        "First Name" => user.first_name,
        "Last Name" => user.last_name,
        "Quantity" => "60",
        "Estimated Cost" => "$39.99",
        "Estimated Subsidy" => "$29.99",
        "Estimated Total" => "$10.00",
        "Calculated Cost" => "$60.00", # default is $1/minute
        "Calculated Subsidy" => "$0.00",
        "Calculated Total" => "$60.00",
        "Actual Cost" => "$199.99",
        "Actual Subsidy" => "$29.99",
        "Actual Total" => "$170.00",
        "Difference Cost" => "$139.99",
        "Difference Subsidy" => "$29.99",
        "Difference Total" => "$110.00",
        "Charge For" => "Minutes",
        "Assigned Staff" => user.full_name,
        "Bundle" => "",
        "Notices" => "",
      )
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
        od.update!(
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
        "Notices" => "",
      )
    end

    describe "with a problem resolution" do
      before do
        order_detail.update!(
          problem_resolved_at: 1.day.ago,
          problem_description_key_was: :missing_actuals,
          problem_resolved_by: user,
        )
      end

      it "has the right fields" do
        expect(report).to have_column_values(
          "Problem Resolved At" => 1.day.ago.to_s,
          "Problem Description" => "Missing Actuals",
          "Problem Resolved By" => user.to_s,
        )
      end
    end

    describe "in review" do
      before { order_detail.update!(reviewed_at: 5.days.from_now) }

      it "includes the correct notice" do
        expect(report).to have_column_values("Notices" => "In Review")
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

    # There was a bug from the Rails 5 upgrade where reservations on split accounts
    # got deleted. We want to make sure the reports don't break on them.
    describe "with a broken reservation" do
      before do
        instrument.price_policies.each { |pp| pp.update(start_date: 3.days.ago, usage_rate: 60) }
        order_detail.reassign_price && order_detail.save!
        reservation.really_destroy!
      end

      it "displays the information" do
        expect(report).to have_column_values(
          "Reservation Start Time" => "",
          "Actual Cost" => "$60.00",
          "Calculated Cost" => "",
          "Quantity" => "1",
        )
      end
    end
  end

  describe "with a bundle" do
    let(:items) { FactoryBot.create_list(:setup_item, 2, facility: facility) }
    let(:bundle) { FactoryBot.create(:bundle, facility: facility, bundle_products: items) }

    let!(:order) { FactoryBot.create(:purchased_order, product: bundle) }
    let(:order_detail) { order.order_details.first }

    it "has the bundle name" do
      expect(report).to have_column_values(
        "Product" => items.map(&:name),
        "Bundle" => [bundle.name, bundle.name],
      )
    end
  end

  describe "with cross core order details" do
    # Defined in spec/support/contexts/cross_core_context.rb
    include_context "cross core orders"

    describe "for order details from a cross core project" do
      let(:order_detail) { facility.orders.first.order_details.first }
      let(:order_details) { facility.orders.flat_map(&:order_details) }

      it "exports correct number of line items" do
        expect(report.to_csv.split("\n").length).to eq(4)
      end

      it "populates the report" do
        expect(report).to have_column_values(
          "Order" => order_details.map(&:to_s),
          "Ordered By" => order_details.map { |od| od.user.username },
          "Cross Core" => order_details.map { |od| od.cross_core?.to_s },
          "Cross Core Project" => order_details.map { |od| od.order.cross_core_project_id.to_s },
          "Cross Core Project Active" => order_details.map { |od| od.order.cross_core_project&.active?.to_s },
        )
      end
    end
  end
end
