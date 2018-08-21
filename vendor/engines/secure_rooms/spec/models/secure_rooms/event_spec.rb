# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::Event do
  it { is_expected.to validate_presence_of :card_reader }
  it { is_expected.to validate_presence_of :occurred_at }
  it { is_expected.to validate_presence_of :outcome }
  it { is_expected.to validate_presence_of :user }
end
