require 'spec_helper'

describe Dataprobe::Ipio do

  let(:ip) { '192.168.10.15' }
  let(:fake_socket) { double 'TCPSocket', recv: nil, write: nil, close: nil }
  subject(:relay) { described_class.new ip }

  before(:each) { TCPSocket.stub(:new).and_return fake_socket }


  it 'initializes with the proper host and defaults' do
    expect(relay.ip).to eq ip
    expect(relay.port).to eq 9100
    expect(relay.username).to match /\Auser/
    expect(relay.password).to match /\Auser/
  end

  it 'initializes with the proper host and overrides' do
    opts = {
      port: 2323,
      username: 'frankie',
      password: 'fingers'
    }

    relay = described_class.new ip, opts
    expect(relay.ip).to eq ip
    expect(relay.port).to eq opts[:port]
    expect(relay.username).to match /\A#{opts[:username]}/
    expect(relay.password).to match /\A#{opts[:password]}/
  end

  it 'turns the relay on' do
    should_toggle
    relay.toggle 4, true
  end

  it 'turns the relay off' do
    should_toggle "\x01"
    relay.toggle 4, false
  end

  it 'raises an error if an unexpected response was given by the socket' do
    should_toggle "\x01", "\x01"
    expect { relay.toggle 4, false }.to raise_error
  end

  it 'indicates that the relay is on' do
    should_give_status :on
  end

  it 'indicates that the relay is off' do
    should_give_status :off
  end


  def should_write_hello
    fake_socket.should_receive(:write).with "hello-000\x00"
  end

  def should_update_sequence
    fake_sequence = [ double('Fixnum') ]
    fake_reply = double 'String', unpack: fake_sequence
    fake_socket.should_receive(:recv).with(2).and_return fake_reply
    fake_reply.should_receive(:unpack).with 's<'
    fake_sequence[0].should_receive(:+).with 1
    fake_sequence.should_receive(:pack).with('s<').and_return "\x01"
  end

  def should_toggle(state_code = "\x00", socket_reply = "\x00")
    should_write_hello
    should_update_sequence
    fake_socket.should_receive(:write).with "\x03#{relay.username}#{relay.password}\x01\x00\x01\x04#{state_code}"
    fake_socket.should_receive(:recv).with(1).and_return socket_reply
    fake_socket.should_receive :close
  end

  def should_give_status(state)
    bool = (state.to_s =~ /\Aon\Z/i).present?
    should_write_hello
    should_update_sequence
    fake_socket.should_receive(:write).with "\x03#{relay.username}#{relay.password}\x04\x00\x01"
    fake_reply = double 'String', unpack: []
    fake_socket.should_receive(:recv).with(8).and_return fake_reply
    fake_reply.should_receive(:unpack).with('C').and_return bool ? [0] : [1]
    fake_socket.should_receive :close
    expect(relay.status 1).to eq bool
  end

end
