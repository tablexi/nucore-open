require "rails_helper"

RSpec.describe Reports::ExportRaw do

  let(:user) { FactoryGirl.create(:user) }
  let(:facility) { FactoryGirl.create(:setup_facility, name: "My Facility", abbreviation: "MF") }
  let(:account) { FactoryGirl.create(:account, :with_account_owner, owner: user) }

  subject(:report) { described_class.new(**report_args) }

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

  describe "for an item" do
    let(:item) { FactoryGirl.create(:setup_item, facility: facility) }
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
        )
      end
    end

    it "exports correct number of line items" do
      expect(report.to_csv.split("\n").length).to eq(2)
    end

    it { is_expected.to have_column(Facility.model_name.human).with_value("My Facility (MF)") }
    it { is_expected.to have_column("Order").with_value(order_detail.to_s) }
    it { is_expected.to have_column("Ordered By").with_value(user.username) }
    it { is_expected.to have_column("First Name").with_value(user.first_name) }
    it { is_expected.to have_column("Last Name").with_value(user.last_name) }
    it { is_expected.to have_column("Quantity").with_value("3") }
    it { is_expected.to have_column("Estimated Cost").with_value("$39.99") }
    it { is_expected.to have_column("Estimated Subsidy").with_value("$29.99") }
    it { is_expected.to have_column("Estimated Total").with_value("$10.00") }
    it { is_expected.to have_column("Actual Cost").with_value("$19.99") }
    it { is_expected.to have_column("Actual Subsidy").with_value("$9.99") }
    it { is_expected.to have_column("Actual Total").with_value("$10.00") }
    it { is_expected.to have_column("Charge For").with_value("Quantity") }

    describe "invoices" do
      it { is_expected.to have_column("Invoice Number").with_value("") }

      describe "with a statement" do
        let(:statement) { create(:statement, facility: facility, created_by: 0, account: account) }
        before { order_detail.update(statement: statement) }
        it { is_expected.to have_column("Invoice Number").with_value("#{account.id}-#{statement.id}") }
      end
    end

  end

  describe "with a reservation", :time_travel do
    let(:now) { Time.zone.parse("2016-02-01 10:30") }
    let(:instrument) { FactoryGirl.create(:setup_instrument, :always_available, facility: facility) }
    let(:reservation) do
      FactoryGirl.create(:completed_reservation,
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

    it { is_expected.to have_column("Reservation Start Time").with_value(reservation.reserve_start_at.to_s) }
    it { is_expected.to have_column("Reservation End Time").with_value(reservation.reserve_end_at.to_s) }
    it { is_expected.to have_column("Reservation Minutes").with_value("60") }
    it { is_expected.to have_column("Actual Start Time").with_value(reservation.actual_start_at.to_s) }
    it { is_expected.to have_column("Actual End Time").with_value(reservation.actual_end_at.to_s) }
    it { is_expected.to have_column("Actual Minutes").with_value("65") }
    it { is_expected.to have_column("Quantity").with_value("1") }
    it { is_expected.to have_column("Charge For").with_value("Reservation") }
  end
end
