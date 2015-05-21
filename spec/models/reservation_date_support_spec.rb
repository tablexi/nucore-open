require 'spec_helper'

describe Reservations::DateSupport do
  subject(:reservation) { create :purchased_reservation, :started_early }

  context '#assign_times_from_params' do
    context 'with a running reservation' do
      before do
        reservation.assign_times_from_params(
          reserve_start_date: "04/17/2015",
          reserve_start_hour: "9",
          reserve_start_min: "0",
          reserve_start_meridian: "AM",
          duration_mins: "60")
      end

      it 'updates start date' do
        expect(reservation.reserve_start_date).to eq("04/17/2015")
      end

      it 'updates start hour' do
        expect(reservation.reserve_start_hour).to eq(9)
      end

      it 'updates start min' do
        expect(reservation.reserve_start_min).to eq(0)
      end

      it 'updates start meridian' do
        expect(reservation.reserve_start_meridian).to eq("AM")
      end

      it 'updates duration mins' do
        expect(reservation.duration_mins).to eq(60)
      end

      it 'updates reserve start at' do
        expect(reservation.reserve_start_at).to eq(DateTime.new(2015, 4, 17, 9, 0, 0, '-5'))
      end

      it 'updates reserve start at' do
        expect(reservation.reserve_end_at).to eq(DateTime.new(2015, 4, 17, 10, 0, 0, '-5'))
      end
    end
  end

  context '#assign_reserve_end_from_actual_duration_mins' do
    before do
      reservation.assign_reserve_end_from_actual_duration_mins(70)
    end

    it 'assigns reserve_end_at' do
      expect(reservation.reserve_end_at).to eq(reservation.reserve_start_at + 65.minutes)
    end
  end
end
