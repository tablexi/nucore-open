require "rails_helper"

RSpec.describe AdminReservationForm do
  include DateHelper

  let(:instrument) { create(:setup_instrument) }
  let(:start_date) { Time.zone.parse("2017-10-17 12:00:00") }
  let(:admin_reservation) { build(:admin_reservation, product: instrument, reserve_start_at: start_date, duration: 1.hour) }
  let!(:form) { AdminReservationForm.new(admin_reservation) }

  describe "validations" do
    describe "cannot_exceed_max_end_date" do
      it "invalid past max end date" do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekly", repeat_end_date: format_usa_date(start_date + 14.weeks))
        expect(form.valid?).to eq false
      end

      it "valid before max end date" do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekly", repeat_end_date: format_usa_date(start_date + 12.weeks))
        expect(form.valid?).to eq true
      end
    end

    describe "repeat_end_date_after_initial_date" do
      it "invalid before initial date" do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekly", repeat_end_date: format_usa_date(start_date - 1.day))
        expect(form.valid?).to eq false
      end

      it "valid after initial date" do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekly", repeat_end_date: format_usa_date(start_date + 1.day))
        expect(form.valid?).to eq true
      end
    end
  end

  describe "build_recurring_reservations" do

    context "weekdays_only" do
      before do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekdays_only", repeat_end_date: format_usa_date(start_date + 7.days))
      end

      it "builds the right number of reservations" do
        expect(form.build_recurring_reservations.length).to eq 6
      end

      it "sets the group id", :aggregate_failures do
        group_ids = form.build_recurring_reservations.map(&:group_id)
        expect(group_ids.uniq.length).to eq 1
        expect(group_ids).to all(be_present)
      end
    end

    context "daily" do
      context "over daylight savings shift" do
        before do
          form.assign_attributes(repeats: "1", repeat_frequency: "daily", repeat_end_date: format_usa_date(start_date + 30.days))
        end

        it "builds the right number of reservations" do
          expect(form.build_recurring_reservations.length).to eq 31
        end

        it "does not change times" do
          start_times = form.build_recurring_reservations.map { |t| t.reserve_start_at.strftime("%H:%M") }
          expect(start_times).to all(eq "12:00")
        end
      end
    end

    context "weekly" do
      before do
        form.assign_attributes(repeats: "1", repeat_frequency: "weekly", repeat_end_date: format_usa_date(start_date + 7.weeks))
      end

      it "builds the right number of reservations" do
        expect(form.build_recurring_reservations.length).to eq 8
      end
    end

    context "monthly" do
      before do
        form.assign_attributes(repeats: "1", repeat_frequency: "monthly", repeat_end_date: format_usa_date(start_date + 3.months))
      end

      it "builds the right number of reservations" do
        expect(form.build_recurring_reservations.length).to eq 4
      end

      context "on the 31st" do
        let(:start_date) { Time.zone.parse("2017-10-31 12:00:00") }

        it "builds reservations with expected dates" do
          expect(form.build_recurring_reservations.map { |t| t.reserve_start_at.strftime("%F") }).to eq ["2017-10-31", "2017-11-30", "2017-12-31", "2018-01-31"]
        end
      end

      context "on the 30th" do
        let(:start_date) { Time.zone.parse("2017-11-30 12:00:00") }

        it "builds reservations with expected dates" do
          expect(form.build_recurring_reservations.map { |t| t.reserve_start_at.strftime("%F") }).to eq ["2017-11-30", "2017-12-30", "2018-01-30", "2018-02-28"]
        end
      end
    end
  end
end
