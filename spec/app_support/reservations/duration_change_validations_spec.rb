require 'spec_helper'

describe Reservations::DurationChangeValidations do

  subject(:validator) { described_class.new(reservation) }
  let(:reservation) { create :setup_reservation }

  describe "#start_time_not_changed" do
    context "with an upcoming reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 1.minute.from_now,
          reserve_end_at: 61.minutes.from_now)
      end

      pending 'change start time'
      pending 'shorten end time'
      pending 'extend end time'
    end

    context "with an ongoing reseration" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 30.minutes.ago,
          reserve_end_at: 30.minutes.from_now)
        reservation.save(validate: false)
      end

      context "change start time" do
        before do
          reservation.assign_attributes(reserve_start_at: 31.minutes.ago)
          validator.valid?
        end

        it 'has an error' do
          expect(validator.errors.full_messages)
            .to include('Reserve start at cannot change once the reservation has started')
        end
      end

      context 'extend end time' do
        before do
          reservation.assign_attributes(reserve_end_at: 31.minutes.from_now)
        end

        it { expect(validator).to be_valid }
      end

      context 'shorten end time' do
        before do
          reservation.assign_attributes(reserve_end_at: 29.minutes.from_now)
          validator.valid?
        end

        it 'has an error' do
          expect(validator.errors.full_messages)
            .to include('Reserve end at cannot shorten once the reservation has started')
        end
      end
    end

    context "with a past reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 61.minutes.ago,
          reserve_end_at: 1.minute.ago)
      end

      pending 'change start time'
      pending 'shorten end time'
      pending 'extend end time'
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
  end
end
