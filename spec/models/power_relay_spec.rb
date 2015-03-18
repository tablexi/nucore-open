require 'spec_helper'

class SomeRelay < Relay
  include PowerRelay
end

describe SomeRelay do

  it { should validate_presence_of :ip }
  it { should validate_presence_of :port }
  it { should validate_presence_of :username }
  it { should validate_presence_of :password }
  it { should_not validate_presence_of :auto_logout_minutes }

  context 'with auto logout' do
    before { subject.auto_logout = true }
    it { should validate_presence_of :auto_logout_minutes }
  end
end
