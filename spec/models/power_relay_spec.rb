require 'spec_helper'

class SomeRelay < Relay
  include PowerRelay
end

describe SomeRelay do

  it { should validate_presence_of :ip }
  it { should validate_presence_of :port }
  it { should validate_presence_of :username }
  it { should validate_presence_of :password }
end
