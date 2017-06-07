require "rails_helper"
require_relative "../../split_accounts_spec_helper"

RSpec.describe Reports::ExportRaw, :enable_split_accounts do
  let(:account) do
    FactoryGirl.build(:split_account, :with_account_owner, without_splits: true, owner: user).tap do |account|
      account.splits << build(:split, percent: 50, apply_remainder: true, subaccount: subaccounts[0], parent_split_account: account)
      account.splits << build(:split, percent: 50, apply_remainder: false, subaccount: subaccounts[1], parent_split_account: account)
      account.save
    end
  end

  let(:subaccounts) { FactoryGirl.create_list(:setup_account, 2) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility) { FactoryGirl.create(:setup_facility) }

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

  describe "with an item" do
    let(:item) { FactoryGirl.create(:setup_item, facility: facility) }
    let(:order_detail) do
      place_product_order(user, facility, item, account).tap do |order_detail|
        order_detail.update_attributes!(
          quantity: 1,
          actual_subsidy: BigDecimal("9.99"),
          actual_cost: BigDecimal("19.99"),
          estimated_subsidy: BigDecimal("29.99"),
          estimated_cost: BigDecimal("39.99"),
        )
      end
    end

    it "splits the values in the report" do
      expect(report).to have_column("Quantity").with_values("0.5", "0.5")
      expect(report).to have_column("Actual Cost").with_values("$10.00", "$9.99")
      expect(report).to have_column("Actual Subsidy").with_values("$5.00", "$4.99")
      expect(report).to have_column("Estimated Cost").with_values("$20.00", "$19.99")
      expect(report).to have_column("Estimated Subsidy").with_values("$15.00", "$14.99")
      expect(report).to have_column("Account").with_values(subaccounts.map(&:account_number))
      expect(report).to have_column("Split Percent").with_values("50%", "50%")
    end
  end

  describe "with a reservation", :time_travel do
    let(:instrument) { FactoryGirl.create(:setup_instrument, :always_available, facility: facility) }
    let(:now) { Time.zone.parse("2016-02-01 10:30") }
    let(:reservation) do
      FactoryGirl.create(:completed_reservation,
                         user: user,
                         product: instrument,
                         reserve_start_at: Time.zone.parse("2016-02-01 08:30"),
                         reserve_end_at: Time.zone.parse("2016-02-01 09:30"),
                         actual_start_at: Time.zone.parse("2016-02-01 08:30"),
                         actual_end_at: Time.zone.parse("2016-02-01 09:35"))
    end
    let(:order_detail) { reservation.order_detail }

    before { order_detail.update_attributes!(account: account) }

    it "splits the fields correctly" do
      expect(report).to have_column("Reservation Start Time").with_values(Array.new(2).fill(reservation.reserve_start_at.to_s))
      expect(report).to have_column("Reservation End Time").with_values(Array.new(2).fill(reservation.reserve_end_at.to_s))
      expect(report).to have_column("Reservation Minutes").with_values("30", "30")
      expect(report).to have_column("Actual Start Time").with_values(Array.new(2).fill(reservation.actual_start_at.to_s))
      expect(report).to have_column("Actual End Time").with_values(Array.new(2).fill(reservation.actual_end_at.to_s))
      expect(report).to have_column("Actual Minutes").with_values("32.5", "32.5")
      expect(report).to have_column("Quantity").with_values("0.5", "0.5")
    end
  end
end
