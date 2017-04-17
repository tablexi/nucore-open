require "rails_helper"

RSpec.describe SecureRooms::Occupancy do
  it { is_expected.to validate_presence_of :product_id }
  it { is_expected.to validate_presence_of :user_id }
end
