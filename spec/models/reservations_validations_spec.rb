require "rails_helper"

RSpec.describe Reservations::Validations do

  subject(:reservation) { build :setup_reservation }

  let(:now) { Time.zone.now }

  it 'validates with #duration_is_interval' do
    expect(reservation).to receive :duration_is_interval
    reservation.save
  end

  it "does not produce an error if the duration of the reservation is a factor of the instrument interval" do
    reservation.product.update_attribute :reserve_interval, 15
    expect(reservation.errors).to be_blank
    reservation.update_attributes reserve_start_at: now, reserve_end_at: now + 1.hour
    expect(reservation.errors).to be_blank
  end

  it "does not produce an error if the duration of the reservation is not a factor of the instrument interval" do
    reservation.product.update_attribute :reserve_interval, 15
    expect(reservation.errors).to be_blank
    reservation.update_attributes reserve_start_at: now, reserve_end_at: now + 1.hour + 5.minutes
    expect(reservation.errors[:base]).to be_present
  end

  describe "starts_before_cutoff" do
    context "when there is a cutoff" do
      before :each do
        reservation.product.update_attribute(:cutoff_hours, 2)
      end

      context "when reservation is after the cutoff" do
        let(:reservation) { build :setup_reservation, reserve_start_at: Time.now + 3.hours }

        it { is_expected.to be_valid }
      end

      context "when reservation is before the cutoff" do
        let(:reservation) { build :setup_reservation, reserve_start_at: Time.now + 1.hour }

        it { is_expected.not_to be_valid }

        it "returns the right errors" do
          reservation.valid?
          expect(reservation.errors).to be_added(:reserve_start_at, :after_cutoff)
        end
      end
    end
  end
end
