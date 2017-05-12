require "rails_helper"

RSpec.describe Reports::ExportRaw do

  let(:user) { create(:user) }
  let(:facility) { secure_room.facility }

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

  describe "normal accounts"

  describe "split accounts", :enable_split_accounts do
    let(:account) { FactoryGirl.create(:split_account, owner: user) }

    describe "with an occupancy", :time_travel do

      let(:now) { Time.zone.parse("2016-02-01 10:30") }
      let(:occupancy) do
        FactoryGirl.create(
                            :occupancy,
                            :with_order_detail,
                            user: user,
                            account: account,
                            entry_at: Time.zone.parse("2016-02-01 08:30"),
                            exit_at: Time.zone.parse("2016-02-01 09:35"),
                          )
      end
      let(:order_detail) { occupancy.order_detail }
      let(:secure_room) { occupancy.secure_room }

      context "for actual_start_at" do
        let(:column_index) { headers.index("Actual Start Time") }

        it "always has the same value" do
          expect(column_values).to be_present
          expect(column_values).to all(eq(occupancy.entry_at.to_s))
        end
      end

      context "for actual_end_at" do
        let(:column_index) { headers.index("Actual End Time") }

        it "always has the same value" do
          expect(column_values).to be_present
          expect(column_values).to all(eq(occupancy.exit_at.to_s))
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

end
