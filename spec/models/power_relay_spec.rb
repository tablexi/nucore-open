# frozen_string_literal: true

require "rails_helper"

class SomeRelay < Relay

  include PowerRelay

end

RSpec.describe SomeRelay do

  it { is_expected.to validate_presence_of :ip }
  it { is_expected.to validate_presence_of :outlet }
  it { is_expected.to validate_presence_of :username }
  it { is_expected.to validate_presence_of :password }
  it { is_expected.not_to validate_presence_of :auto_logout_minutes }

  context "with auto logout" do
    before { subject.auto_logout = true }
    it { is_expected.to validate_presence_of :auto_logout_minutes }
  end
end
