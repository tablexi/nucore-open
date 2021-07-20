# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalCutoffDate do
  it { is_expected.to validate_presence_of(:cutoff_date) }

  describe "cutoff_date" do
    subject(:hash) { described_class.new(cutoff_date: cutoff_date).cutoff_date_date_time_data.to_h }
    describe "am" do
      let(:cutoff_date) { Time.zone.parse("2016-01-01 08:45") }
      it { is_expected.to eq(date: "01/01/2016", hour: 8, minute: 45, ampm: "AM") }
    end

    describe "pm" do
      let(:cutoff_date) { Time.zone.parse("2016-01-01 16:37") }
      it { is_expected.to eq(date: "01/01/2016", hour: 4, minute: 37, ampm: "PM") }
    end

    describe "midnight" do
      let(:cutoff_date) { Time.zone.parse("2016-04-01 00:10") }
      it { is_expected.to eq(date: "04/01/2016", hour: 12, minute: 10, ampm: "AM") }
    end

    describe "noon" do
      let(:cutoff_date) { Time.zone.parse("2016-01-01 12:00") }
      it { is_expected.to eq(date: "01/01/2016", hour: 12, minute: 0, ampm: "PM") }
    end
  end

  describe "cutoff_date=" do
    let(:model) do
      described_class.new(cutoff_date: cutoff_date_hash)
    end

    subject(:cutoff_date) { model.cutoff_date }

    describe "am" do
      let(:cutoff_date_hash) { { date: "02/01/2016", hour: "8", minute: "45", ampm: "AM" } }
      it { is_expected.to eq(Time.zone.parse("2016-02-01 08:45")) }
    end

    describe "pm" do
      let(:cutoff_date_hash) { { date: "02/01/2016", hour: "4", minute: "37", ampm: "PM" } }
      it { is_expected.to eq(Time.zone.parse("2016-02-01 16:37")) }
    end

    describe "midnight" do
      let(:cutoff_date_hash) { { date: "02/01/2016", hour: "12", minute: "10", ampm: "AM" } }
      it { is_expected.to eq(Time.zone.parse("2016-02-01 00:10")) }
    end

    describe "noon" do
      let(:cutoff_date_hash) { { date: "02/01/2016", hour: "12", minute: "00", ampm: "PM" } }
      it { is_expected.to eq(Time.zone.parse("2016-02-01 12:00")) }
    end
  end

  describe "month validation" do
    it "does not allow more than in the same month" do
      existing = described_class.create(cutoff_date: Time.zone.parse("2016-02-03 12:00"))

      new_date = described_class.new(cutoff_date: Time.zone.parse("2016-02-07 12:00"))
      expect(new_date).to be_invalid
      expect(new_date.errors[:cutoff_date]).to include("There is already a cutoff date for February")
    end

    it "allows more than one in separate months" do
      existing = described_class.create(cutoff_date: Time.zone.parse("2016-02-03 12:00"))

      new_date = described_class.new(cutoff_date: Time.zone.parse("2016-03-03 12:00"))
      expect(new_date).to be_valid
    end

    it "allows more than one of the same month, but different years" do
      existing = described_class.create(cutoff_date: Time.zone.parse("2016-02-03 12:00"))

      new_date = described_class.new(cutoff_date: Time.zone.parse("2017-02-03 12:00"))
      expect(new_date).to be_valid
    end

    it "allows an already persisted record not to conflict with itself" do
      existing = described_class.create(cutoff_date: Time.zone.parse("2016-02-03 12:00"))
      expect(existing).to be_valid
    end
  end

  describe "#last_valid_date" do
    subject(:last_valid_date) { described_class.new(cutoff_date: cutoff_date).last_valid_date }

    describe "early in the month" do
      let(:cutoff_date) { Time.zone.parse("2016-04-02") }
      it { is_expected.to eq(Time.zone.parse("2016-03-31").end_of_day) }
    end

    describe "late in the month" do
      let(:cutoff_date) { Time.zone.parse("2016-06-30") }
      it { is_expected.to eq(Time.zone.parse("2016-05-31").end_of_day) }
    end

    describe "leap year" do
      let(:cutoff_date) { Time.zone.parse("2016-03-02") }
      it { is_expected.to eq(Time.zone.parse("2016-02-29").end_of_day) }
    end

    describe "january" do
      let(:cutoff_date) { Time.zone.parse("2016-01-02") }
      it { is_expected.to eq(Time.zone.parse("2015-06-01").end_of_year) }
    end
  end

  describe "#year_end_closing_window?", :time_travel do
    subject(:closing_window) { described_class.year_end_closing_window? }

    context "with no journal cutoff records" do
      it { is_expected.to be false }
    end

    context "with no journal cutoff for year end" do
      before { described_class.create(cutoff_date: 6.months.ago) }
      it { is_expected.to be false }
    end

    context "with a journal cutoff for year end" do
      let!(:year_end_cutoff) { described_class.create(cutoff_date: 1.week.from_now) }

      describe "during the year end closing window" do
        it { is_expected.to be true }
      end

      describe "after the year end closing window" do
        let(:now) { 2.weeks.from_now }
        it { is_expected.to be false }
      end

      describe "before the year end closing window" do
        let(:now) { 11.days.ago }
        it { is_expected.to be false }
      end

      describe "at the moment of the last_valid_date" do
        # Tue, 31 Aug 2021 23:59:59 CDT -05:00
        let(:now) { year_end_cutoff.last_valid_date }
        it { is_expected.to be false }
      end

      describe "at the moment of the year end cutoff date" do
        # Sat, 18 Sep 2021 09:30:00 CDT -05:00
        let(:now) { year_end_cutoff.cutoff_date }
        it { is_expected.to be false }
      end
    end
  end

  describe "#year_end" do
    subject(:year_end) { described_class.year_end }

    context "with no journal cutoff records" do
      it { is_expected.to be nil }
    end

    context "with no journal cutoff for year end" do
      before { described_class.create(cutoff_date: 6.months.ago) }
      it { is_expected.to be nil }
    end

    context "with a journal cutoff for year end" do
      let!(:year_end_cutoff) { described_class.create(cutoff_date: 1.week.from_now) }

      it { is_expected.to eq year_end_cutoff }

      describe "and a cutoff for the same month, next year" do
        let!(:year_end_cutoff_next_year) { described_class.create(cutoff_date: 1.week.from_now + 1.year) }

        it { is_expected.to eq year_end_cutoff }
      end
    end
  end
end
