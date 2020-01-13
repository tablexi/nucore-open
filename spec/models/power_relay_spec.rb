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

  it "allows a numerical or nil port allocation" do
    relay = SomeRelay.new(ip: "123", username: "nucore", password: "password", outlet: 1, instrument_id: 1)

    expect(relay.update(port: 3000)).to be true
    expect(relay.update(port: "three thousand")).to be false
    expect(relay.update(port: nil)).to be true
  end

  context "with auto logout" do
    before { subject.auto_logout = true }
    it { is_expected.to validate_presence_of :auto_logout_minutes }
  end
end
