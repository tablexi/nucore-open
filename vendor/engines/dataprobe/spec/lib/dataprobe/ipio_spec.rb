# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dataprobe::Ipio do
  let(:ip) { "192.168.10.15" }
  let(:fake_socket) { double "TCPSocket", recv: nil, write: nil, close: nil }
  subject(:relay) { described_class.new ip }

  before(:each) { allow(TCPSocket).to receive(:new).and_return fake_socket }

  it "initializes with the proper host and defaults" do
    expect(relay.ip).to eq ip
    expect(relay.port).to eq 9100
    expect(relay.username).to match /\Auser/
    expect(relay.password).to match /\Auser/
  end

  it "initializes with the proper host and overrides" do
    opts = {
      port: 2323,
      username: "frankie",
      password: "fingers",
    }

    relay = described_class.new ip, opts
    expect(relay.ip).to eq ip
    expect(relay.port).to eq opts[:port]
    expect(relay.username).to match /\A#{opts[:username]}/
    expect(relay.password).to match /\A#{opts[:password]}/
  end

  it "turns the relay on" do
    should_toggle
    state = relay.toggle 4, true
    expect(state).to eq(true)
  end

  it "turns the relay off" do
    should_toggle "\x00"
    state = relay.toggle 4, false
    expect(state).to eq(false)
  end

  it "raises an error if an unexpected response was given by the socket" do
    should_toggle "\x00", "\x01"
    expect { relay.toggle 4, false }.to raise_error(Dataprobe::Error)
  end

  it "indicates that the relay is on" do
    should_give_status :on
  end

  it "indicates that the relay is off" do
    should_give_status :off
  end

  def should_write_hello
    expect(fake_socket).to receive(:write).with "hello-000\x00"
  end

  def should_update_sequence
    fake_sequence = [double("Integer")]
    fake_reply = double "String", unpack: fake_sequence
    expect(fake_socket).to receive(:recv).with(2).and_return fake_reply
    expect(fake_reply).to receive(:unpack).with "s<"
    expect(fake_sequence[0]).to receive(:+).with 1
    expect(fake_sequence).to receive(:pack).with("s<").and_return "\x01"
  end

  def should_toggle(state_code = "\x01", socket_reply = "\x00")
    should_write_hello
    should_update_sequence
    expect(fake_socket).to receive(:write).with "\x03#{relay.username}#{relay.password}\x01\x00\x01\x04#{state_code}"
    expect(fake_socket).to receive(:recv).with(1).and_return socket_reply
    expect(fake_socket).to receive :close
  end

  def should_give_status(state)
    bool = (state.to_s =~ /\Aon\Z/i).present?
    should_write_hello
    should_update_sequence
    expect(fake_socket).to receive(:write).with "\x03#{relay.username}#{relay.password}\x04\x00\x01"
    fake_reply = double "String", unpack: []
    expect(fake_socket).to receive(:recv).with(100).and_return fake_reply
    expect(fake_reply).to receive(:unpack).with("C*").and_return bool ? [1] : [0]
    expect(fake_socket).to receive :close
    expect(relay.status 1).to eq bool
  end
end
