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
end
