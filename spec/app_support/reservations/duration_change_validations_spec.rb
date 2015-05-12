require 'spec_helper'

describe Reservations::DurationChangeValidations do

  subject(:validator) { described_class.new(reservation) }
  let(:reservation) { create :setup_reservation }

  describe "#start_time_not_changed" do
    context "with an upcoming reservation" do
      let(:reservation) { create :setup_reservation, reserve_start_at: 5.minute.from_now, reserve_end_at: 70.minutes.from_now }

      it 'allows changing start time' do
        reservation.reserve_start_at = 10.minutes.from_now
        validator.valid?
        expect(validator.errors).to be_empty
      end

      it 'allows shortening end time' do
        reservation.reserve_end_at = 65.minutes.from_now
        validator.valid?
        expect(validator.errors).to be_empty
      end
    end

    context "with an ongoing reseration" do
      let(:reservation) { create :setup_reservation, reserve_start_at: 30.minutes.ago, reserve_end_at: 40.minutes.from_now }

      it 'denies changing start time' do
        reservation.reserve_start_at = 40.minutes.ago
        validator.valid?
        expect(validator.errors.full_messages)
          .to include('Reserve start at cannot change once the reservation has started')
      end

      it 'denies shortening end time' do
        reservation.reserve_end_at = 35.minutes.from_now
        validator.valid?
        expect(validator.errors.full_messages)
          .to include('Reserve end at cannot be shortened once the reservation has started')
      end
    end

    context "with a past reservation" do
      let(:reservation) { create :setup_reservation, reserve_start_at: 15.minutes.ago, reserve_end_at: 5.minutes.ago, product: create(:setup_instrument, min_reserve_mins: 5) }

      it 'denies changing start time' do
        reservation.reserve_start_at = 10.minutes.ago
        validator.valid?
        expect(validator.errors.full_messages)
          .to include('Reserve start at cannot change once the reservation has started')
      end

      it 'denies shortening end time' do
        reservation.reserve_end_at = 10.minutes.ago
        validator.valid?
        expect(validator.errors.full_messages)
          .to include('Reserve end at cannot be shortened once the reservation has started')
      end
    end
  end

  describe "#copy_errors!" do
    before do
      validator.errors.add(:base, 'I am an error')
      validator.copy_errors!
    end

    it "copies errors to reservation" do
      reservation.errors.full_messages.include?('I am an error')
    end
  end

  describe "#invalid?" do
    before do
      validator.errors.add(:base, 'I am an error')
      validator.invalid?
    end

    it "copies errors to reservation" do
      reservation.errors.full_messages.include?('I am an error')
    end
  end

  describe "#duration_not_shortened" do
    context "with an upcoming reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 1.minute.from_now,
          reserve_end_at: 61.minutes.from_now)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.from_now)
      end

      it { expect(validator).to be_valid }
    end

    context "with an ongoing reseration" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 30.minutes.ago,
          reserve_end_at: 30.minutes.from_now)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 1.minute.from_now)
      end

      it { expect(validator).to be_invalid }
    end

    context "with a past reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 61.minutes.ago,
          reserve_end_at: 1.minute.ago)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.ago)
      end

      it { expect(validator).to be_invalid }
    end

    context "with a relay reservation started early" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 1.minute.from_now,
          reserve_end_at: 61.minutes.from_now,
          actual_start_at: 1.minute.ago)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.from_now)
      end

      it { expect(validator).to be_invalid }
    end
  end
end
