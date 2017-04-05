require "rails_helper"

RSpec.describe SecureRooms::Event do
  it { is_expected.to validate_presence_of :occurred_at }
end
