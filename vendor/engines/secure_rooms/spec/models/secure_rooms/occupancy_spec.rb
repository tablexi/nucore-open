require "rails_helper"

RSpec.describe SecureRooms::Occupancy do
  it { is_expected.to validate_presence_of :secure_room }
  it { is_expected.to validate_presence_of :user }
end
