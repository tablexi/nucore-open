# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }
  it { is_expected.to validate_uniqueness_of :card_number }
  it { is_expected.to validate_uniqueness_of :i_class_number }
end
