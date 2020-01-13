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

  it "should allow a range of 1-16 outlets" do
    relay = SomeRelay.new(ip: "123", username: "nucore", password: "password")
    expect(relay.update(outlet: 16)).to be true
    expect(relay.update(outlet: 17)).to be false
  end

  context "with auto logout" do
    before { subject.auto_logout = true }
    it { is_expected.to validate_presence_of :auto_logout_minutes }
  end
end
