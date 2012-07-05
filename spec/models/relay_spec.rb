require 'spec_helper'

describe Relay do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :ip }
  it { should allow_mass_assignment_of :port }
  it { should allow_mass_assignment_of :auto_logout }
  it { should allow_mass_assignment_of :instrument_id }
  it { should allow_mass_assignment_of :type }


  context 'with relay' do

    before :each do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @relay            = Factory.create(:relay, :instrument => @instrument)
    end

    it { should validate_uniqueness_of(:port).scoped_to(:ip) }

    it 'should alias host to ip' do
      @relay.host.should == @relay.ip
    end

    context 'dummy relay' do

      before :each do
        @relay.destroy
        @relay.should be_destroyed
        @relay=RelayDummy.create!(:instrument_id => @instrument.id)
      end


      it 'should turn on the relay' do
        @relay.activate
        @relay.get_status.should == true
      end


      it 'should turn off the relay' do
        @relay.deactivate
        @relay.get_status.should == false
      end

    end

  end

end