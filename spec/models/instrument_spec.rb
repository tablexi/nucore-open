require 'spec_helper'
require 'product_shared_examples'

describe Instrument do
  it_should_behave_like 'ReservationProduct', :instrument
  
  context "factory" do
    it "should create using factory" do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @instrument.should be_valid
      @instrument.type.should == 'Instrument'
    end
  end

  [ :min_reserve_mins, :max_reserve_mins, :auto_cancel_mins ].each do |attr|
    it "should require #{attr} to be >= 0 and integers only" do
      should allow_value(0).for(attr)
      should_not allow_value(-1).for(attr)
      should_not allow_value(5.0).for(attr)
    end
  end

  context "updating nested relay" do
    before :each do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    end

    context "existing type: 'timer' (Timer without relay)" do
      before :each do
        @instrument.relay = RelayDummy.new
        @instrument.relay.save!
        @instrument.control_mechanism.should == 'timer'
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => {:type => 'RelaySynaccessRevA'})
          end

          it "should fail" do
            @updated.should be_false
          end

          it "should have errors" do
            @instrument.errors.full_messages.should_not == []
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => Factory.attributes_for(:relay)) 
          end

          it "should succeed" do
            @updated.should be_true
          end

          it "should have no errors" do
            @instrument.errors.full_messages.should == []
          end
          
          it "should have control mechanism of relay" do
            @instrument.reload.control_mechanism.should == 'relay'
          end
        end
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'manual')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "should have a control_mechanism of manual" do
          @instrument.reload.control_mechanism.should == 'manual'
        end

        it "should destroy the relay" do
          @instrument.reload.relay.should be_nil
        end
      end
    end

    context "existing type: RelaySynaccessA" do
      before :each do
        Factory.create(:relay, :instrument_id => @instrument.id)
        @instrument.reload.control_mechanism.should == 'relay'
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'manual')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "should have a control_mechanism of manual" do
          @instrument.reload.control_mechanism.should == 'manual'
        end

        it "should destroy the relay" do
          @instrument.reload.relay.should be_nil
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'timer')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "control mechanism should be a timer" do
          @instrument.reload.control_mechanism.should == 'timer'
        end
      end
    end

    context "existing type: manual 'Reservation Only'" do
      before :each do
        @instrument.relay.destroy if @instrument.relay
        @instrument.reload.control_mechanism.should == Relay::CONTROL_MECHANISMS[:manual]
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => {:type => 'RelaySynaccessRevA'}) 
          end

          it "should fail" do
            @updated.should be_false
          end

          it "should have errors" do
            @instrument.errors.full_messages.should_not == []
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => Factory.attributes_for(:relay)) 
          end
          it "should succeed" do
            @updated.should be_true
          end

          it "should have no errors" do
            @instrument.errors.full_messages.should == []
          end

          it "should have control mechanism of relay" do
            @instrument.reload.control_mechanism.should == 'relay'
          end
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'timer')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "control mechanism should be a timer" do
          @instrument.reload.control_mechanism.should == 'timer'
        end
      end
    end
  end
  
  context "reservations with schedule rules from 9 am to 5 pm every day, with 60 minute durations" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @options          = Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id,
                                                 :min_reserve_mins => 60, :max_reserve_mins => 60)
      @instrument       = @facility.instruments.create(@options)
      assert @instrument.valid?
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      Reservation.any_instance.stubs(:admin?).returns(false)
    end
    
    it "should not allow reservation in the past" do
      @reservation = @instrument.reservations.create(:reserve_start_at => Time.zone.now - 1.hour, :reserve_end_at => Time.zone.now)
      assert @reservation.errors[:reserve_start_at]
    end
    
    it "should not allow 1 hour reservation for a time not between 9 and 5" do
      # 8 am - 9 am
      @start       = Time.zone.now.end_of_day + 1.second + 8.hours
      @reservation = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start + 1.hour)
      assert @reservation.errors[:base]
    end

    it "should not allow a 2 hour reservation" do
      # 8 am - 10 pam
      @start       = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start + 2.hours)
      assert @reservation.errors[:base]
    end

    it "should allow 1 hour reservations between 9 and 5" do
      # 9 am - 10 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # should allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+1.hour, :reserve_end_at => @start+2.hours)
      assert @reservation2.valid?
      # should find 2 upcoming reservations when both are in the future
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming
      # should find 2 upcoming reservations when both are in the future or happening now
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming(@start+1.minute)
      # should find 1 upcoming when 1 is in the past
      assert_equal [@reservation2], @instrument.reservations.upcoming(@start+1.hour)
    end

    it "should allow 1 hour reservations between 9 and 5, using duration_value, duration_unit virtual attribute" do
      # 9 am - 10 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation1.valid?
      assert_equal 60, @reservation1.reload.duration_mins
    end

    it "should not allow overlapping reservations between 9 and 5" do
      # 10 am - 11 am
      @start        = Time.zone.now.end_of_day + 1.second + 10.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # not allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 10:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-30.minutes, :reserve_end_at => @start+30.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 10:30 am, using reserve_start_date, reserve_start_hour, reserve_start_min, reserve_start_meridian
      @options      = {:reserve_start_date => @start.to_s, :reserve_start_hour => '9', :reserve_start_min => '30',
                       :reserve_start_meridian => 'am', :duration_value => '60', :duration_unit => 'minutes'}
      @reservation2 = @instrument.reservations.create(@options)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-30.minutes, :reserve_end_at => @start+90.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 10:30 am - 10:45 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+30.minutes, :reserve_end_at => @start+45.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 10:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+30.minutes, :reserve_end_at => @start+90.minutes)
      @reservation2.errors[:base].should_not be_empty
    end

    it "should allow adjacent reservations" do
      # 10 am - 11 am
      @start        = Time.zone.now.end_of_day + 1.second + 10.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # should allow 9 am - 10 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-1.hour, :reserve_end_at => @start)
      assert @reservation2.valid?
      # should allow 11 am - 12 pm
      @reservation3 = @instrument.reservations.create(:reserve_start_at => @start+1.hour, :reserve_end_at => @start+2.hours)
      assert @reservation3.valid?
    end
  end

  context "next available reservation based on schedule rules" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @options          = Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id,
                                                 :min_reserve_mins => 60, :max_reserve_mins => 60)
      @instrument       = @facility.instruments.create(@options)
      assert @instrument.valid?
    end
    
    it "should find next available reservation with 60 minute interval rule, without any pending reservations" do
      # add rule, available every day from 9 to 5, 60 minutes duration/interval
      @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      # stub so today at 9 am is not in the future
      Reservation.any_instance.stubs(:in_the_future).returns(true)
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      # find next reservation after 9:01 am today at 10 am today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+9.hours+1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 4:01 pm today at 9 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+16.hours+1.minute)
      assert_equal (Time.zone.now+1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
    end

    it "should find next available reservation with 5 minute interval rule, without any pending reservations" do
      # add rule, available every day from 9 to 5, 5 minute duration/interval
      @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :duration_mins => 5))
      assert @rule.valid?
      # stub so today at 9 am is not in the future
      Reservation.any_instance.stubs(:in_the_future).returns(true)
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 9:01 am today at 9:05 am today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+9.hours+1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 5, @next_reservation.reserve_start_at.min
      # find next reservation after 3:45 pm today at 3:45 pm today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+15.hours+45.minutes)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 15, @next_reservation.reserve_start_at.hour
      assert_equal 45, @next_reservation.reserve_start_at.min
    end

    it "should find next available reservation with pending reservations" do
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      # add reservation for tomorrow morning at 9 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation1.valid?
      # find next reservation after 12 am tomorrow at 10 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.end_of_day+1.second)
      assert_equal (Time.zone.now+1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
    end
  end

  context "available hours based on schedule rules" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @options          = Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id,
                                                 :min_reserve_mins => 60, :max_reserve_mins => 60)
      @instrument       = @facility.instruments.create(@options)
      assert @instrument.valid?
    end
    
    it "should have first avail hour at 9 am, last avail hour at 4 pm, with every day rule from 9 to 5" do
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      @instrument.first_available_hour.should == 9
      @instrument.last_available_hour.should == 16
    end
  end

  context "last reserve dates, days from now" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @options          = Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id,
                                                 :min_reserve_mins => 60, :max_reserve_mins => 60)
      @instrument       = @facility.instruments.create(@options)
      @price_group_product=Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group)
      assert @instrument.valid?
      
      # create price policy with default window of 1 day
      @price_policy     = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    end

    it "should have last_reserve_date == tomorrow, last_reserve_days_from_now == 1 when window is 1" do
      @instrument.price_group_products.each{|pgp| pgp.update_attributes(:reservation_window => 1) }
      assert_equal Time.zone.now.to_date + 1.day, @instrument.reload.last_reserve_date
      assert_equal 1, @instrument.max_reservation_window
    end
    
    it "should use max window of all price polices to calculate dates" do
      # create price policy with window of 15 days
      @price_group_product.reservation_window=15
      assert @price_group_product.save
      @options       = Factory.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id)
      @price_policy2 = @instrument.instrument_price_policies.new(@options)
      @price_policy2.save(:validate => false) # save without validations
      assert_equal 15, @instrument.max_reservation_window
      assert_equal (Time.zone.now+15.days).to_date, @instrument.last_reserve_date
    end
  end

  context 'can_purchase?' do
    before :each do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @price_group = Factory.create(:price_group, :facility => @facility)
      @user = Factory.create(:user)
      Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @user.reload
      @user_price_policy_ids = @user.price_groups.map(&:id)
      @price_policy = Factory.create(:instrument_price_policy, :product => @instrument, :price_group => @price_group)
      #TODO remove this line
      Factory.create(:price_group_product, :price_group => @price_group, :product => @instrument)
    end
    it 'should be purchasable if there are schedule rules' do
      @schedule_rule = Factory.create(:schedule_rule, :instrument => @instrument)
      @instrument.reload
      @instrument.should be_can_purchase(@user_price_policy_ids)
    end
    it 'should not be purchasable if there are no schedule rules' do
      @instrument.should_not be_can_purchase(@user_price_policy_ids)
    end
  end
end
