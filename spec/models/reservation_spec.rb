require 'spec_helper'

describe Reservation do
  include DateHelper

  before(:each) do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    # add rule, available every day from 12 am to 5 pm, 60 minutes duration
    @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(:start_hour => 0, :end_hour => 17, :duration_mins => 15))
  end


  context "create using virtual attributes" do
    it "should create using date, integer values" do
      @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                     :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                     :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation.valid?
      @reservation.reload.duration_value.should == 60
      @reservation.reserve_start_hour.should == 10
      @reservation.reserve_start_min.should == 0
      @reservation.reserve_start_meridian.should == 'am'
      @reservation.reserve_end_hour.should == 11
      @reservation.reserve_end_min.should == 0
      @reservation.reserve_end_meridian.should == 'AM'
    end

    it "should create using string values" do
      @reservation = @instrument.reservations.create(:reserve_start_date => (Date.today+1.day).to_s, :reserve_start_hour => '10',
                                                     :reserve_start_min => '0', :reserve_start_meridian => 'am',
                                                     :duration_value => '2', :duration_unit => 'hours')
      assert @reservation.valid?
      @reservation.reload.duration_mins.should == 120
      @reservation.reserve_start_hour.should == 10
      @reservation.reserve_start_min.should == 0
      @reservation.reserve_start_meridian.should == 'am'
      @reservation.reserve_end_hour.should == 12
      @reservation.reserve_end_min.should == 0
      @reservation.reserve_end_meridian.should == 'PM'
    end
  end


  context 'cancelled?' do
    before :each do
      @reservation = @instrument.reservations.create(:reserve_start_date => (Date.today+1.day).to_s, :reserve_start_hour => '10',
                                                     :reserve_start_min => '0', :reserve_start_meridian => 'am',
                                                     :duration_value => '2', :duration_unit => 'hours')
      assert @reservation.valid?
    end


    it('should not be cancelled') { @reservation.should_not be_cancelled }

    it 'should be cancelled' do
      @reservation.canceled_at=Time.zone.now
      @reservation.should be_cancelled
    end
  end


  context 'with order details' do

    before :each do
      @facility      = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group   = Factory.create(:price_group, :facility => @facility)
      @instrument_pp = Factory.create(:instrument_price_policy, :instrument => @instrument, :price_group => @price_group)
      @user          = Factory.create(:user)
      @pg_member     = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account       = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order         = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
      @detail1       = @order.order_details.create(:product_id => @instrument.id, :quantity => 1, :account => @account)
      @detail2       = @order.order_details.create(:product_id => @instrument.id, :quantity => 1)

      @instrument.min_reserve_mins = 15
      @instrument.save

      @reservation1  = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                       :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                       :duration_value => 30, :duration_unit => 'minutes', :order_detail => @detail1)
    end

    it 'should be the same order' do
      @reservation1.order.should == @detail1.order
    end

    it 'should not allow two reservations with the same order detail id' do
      reservation2=@instrument.reservations.new(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                :duration_value => 30, :duration_unit => 'minutes', :order_detail => @reservation1.order_detail)
      assert !reservation2.save
      reservation2.errors[:order_detail].should_not be_nil
    end

    it 'should be the same user' do
      @reservation1.user.should == @detail1.order.user
    end

    it 'should be the same account' do
      @detail1.account.should_not be_nil
      @reservation1.account.should == @detail1.account
    end

    it 'should be the same owner' do
      @detail1.account.owner.should_not be_nil
      @reservation1.owner.should == @detail1.account.owner
    end

    it "should not allow reservations to conflict with an existing reservation in the same order" do
      @reservation1.should be_valid

      @reservation2  = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                       :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                       :duration_value => 30, :duration_unit => 'minutes', :order_detail => @detail2)
      @reservation2.should_not be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]

      @reservation2  = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                       :reserve_start_min => 15, :reserve_start_meridian => 'am',
                                                       :duration_value => 30, :duration_unit => 'minutes', :order_detail => @detail2)
      @reservation2.should_not be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]

      @reservation2  = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 9,
                                                       :reserve_start_min => 45, :reserve_start_meridian => 'am',
                                                       :duration_value => 30, :duration_unit => 'minutes', :order_detail => @detail2)
      @reservation2.should_not be_valid
      assert_equal ["The reservation conflicts with another reservation in your cart. Please purchase or remove it then continue."], @reservation2.errors[:base]
    end

    it "should allow reservations with the same time and date on different instruments" do
      @reservation1.should be_valid

      @reservation2  = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                       :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                       :duration_value => 30, :duration_unit => 'minutes', :order_detail => @detail2)

      @reservation2.should_not be_does_not_conflict_with_other_reservation

      @instrument2 = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))

      @reservation2.instrument=@instrument2
      @reservation2.should be_does_not_conflict_with_other_reservation
    end

    context 'moving' do

      before(:each) { @morning=Time.local(Date.today.year, Date.today.month, Date.today.day, 10, 31) }

      it 'should return the earliest possible time slot' do
        human_date(@reservation1.reserve_start_at).should == human_date(@morning+1.day)

        earliest=nil
        Timecop.freeze(@morning) { earliest=@reservation1.earliest_possible }
        human_date(earliest.reserve_start_at).should == human_date(@morning)

        new_min=0

        (@morning.min..60).each do |min|
          new_min=min == 60 ? 0 : min
          earliest.reserve_start_at.min.should == new_min and break if new_min % @rule.duration_mins == 0
        end

        earliest.reserve_start_at.hour.should == (new_min == 0 ? @morning.hour+1 : @morning.hour)
        (earliest.reserve_end_at-earliest.reserve_start_at).should == (@reservation1.reserve_end_at-@reservation1.reserve_start_at)
      end

      it 'should not be moveable if the reservation is cancelled' do
        @reservation1.should be_can_move
        @reservation1.canceled_at=Time.zone.now
        @reservation1.should_not be_can_move
      end

      it 'should not be moveable if there is not a time slot earlier than this one' do
        @reservation1.should be_can_move
        @reservation1.move_to!(@reservation1.earliest_possible)
        @reservation1.should_not be_can_move
      end

      it 'should update the reservation to the earliest available' do
        earliest=@reservation1.earliest_possible
        @reservation1.reserve_start_at.should_not == earliest.reserve_start_at
        @reservation1.reserve_end_at.should_not == earliest.reserve_end_at
        @reservation1.move_to!(earliest)
        @reservation1.reserve_start_at.should == earliest.reserve_start_at
        @reservation1.reserve_end_at.should == earliest.reserve_end_at
      end
    end

    context 'requires_but_missing_actuals?' do

      it 'should be true when there is a usage rate but no actuals' do
        @instrument_pp.usage_rate=5
        assert @instrument_pp.save

        @reservation1.actual_start_at.should be_nil
        @reservation1.actual_end_at.should be_nil
        @reservation1.order_detail.price_policy=@instrument_pp
        assert @reservation1.save

        @reservation1.should be_requires_but_missing_actuals
      end


      it 'should be false when there is no price policy' do
        @reservation1.actual_start_at=1.day.ago
        @reservation1.actual_end_at=1.day.ago+1.hour
        assert @reservation1.save

        @reservation1.order_detail.price_policy.should be_nil
        @reservation1.should_not be_requires_but_missing_actuals
      end


      it 'should be false when price policy has no usage rate' do
        @instrument_pp.usage_rate.should_not be_present

        @reservation1.order_detail.price_policy=@instrument_pp
        @reservation1.actual_start_at=1.day.ago
        @reservation1.actual_end_at=1.day.ago+1.hour
        assert @reservation1.save

        @reservation1.should_not be_requires_but_missing_actuals
      end


      it 'should be false when price policy has zero usage rate' do
        @instrument_pp.usage_rate=0
        assert @instrument_pp.save

        @reservation1.order_detail.price_policy=@instrument_pp
        @reservation1.actual_start_at=1.day.ago
        @reservation1.actual_end_at=1.day.ago+1.hour
        assert @reservation1.save

        @reservation1.should_not be_requires_but_missing_actuals
      end


      it 'should be false when there is a usage rate and actuals' do
        @instrument_pp.usage_rate=5
        assert @instrument_pp.save

        @reservation1.order_detail.price_policy=@instrument_pp
        @reservation1.actual_start_at=1.day.ago
        @reservation1.actual_end_at=1.day.ago+1.hour
        assert @reservation1.save

        @reservation1.should_not be_requires_but_missing_actuals
      end

    end

  end


  it "should not let reservations exceed the maximum length" do
    @instrument.max_reserve_mins = 60
    @instrument.save
    @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                   :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                   :duration_value => 61, :duration_unit => 'minutes')
    assert @reservation.invalid?
    assert_equal ["The reservation is too long"], @reservation.errors[:base]
    @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                   :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                   :duration_value => 60, :duration_unit => 'minutes')
    assert @reservation.valid?
  end

  it "should not let reservations be under the minimum length" do
    @instrument.min_reserve_mins = 30
    @instrument.save
    @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                   :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                   :duration_value => 29, :duration_unit => 'minutes')
    assert @reservation.invalid?
    assert_equal ["The reservation is too short"], @reservation.errors[:base]
    @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                   :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                   :duration_value => 30, :duration_unit => 'minutes')
    assert @reservation.valid?
  end
   
  it "should allow multi-day registrations" do
    # set max reserve to 4 hours
    @instrument.max_reserve_mins = 240
    @instrument.save
    @today        = Date.today
    @tomorrow     = @today+1.day
    # should not allow multi-day reservation with existing rules
    @reservation  = @instrument.reservations.create(:reserve_start_date => @tomorrow, :reserve_start_hour => 10,
                                                    :reserve_start_min => 0, :reserve_start_meridian => 'pm',
                                                    :duration_value => 4, :duration_unit => 'hours')
    assert @reservation.invalid?
    # create rule2 that is adjacent to rule (10 pm to 12 am), allowing multi-day reservations
    @rule2        = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(:start_hour => 22, :end_hour => 24))
    assert @rule2.valid?
    @reservation  = @instrument.reservations.create(:reserve_start_date => @tomorrow, :reserve_start_hour => 10,
                                                    :reserve_start_min => 0, :reserve_start_meridian => 'pm',
                                                    :duration_value => 4, :duration_unit => 'hours')
    assert @reservation.valid?
  end

  context "basic reservation rules" do
    it "should not allow reservations starting before now" do
      @earlier = Date.today - 1
      @reservation = @instrument.reservations.create(:reserve_start_date => @earlier, :reserve_start_hour => 10,
                                      :reserve_start_min => 0, :reserve_start_meridian => 'pm',
                                      :duration_value => 4, :duration_unit => 'hours')
      assert @reservation.invalid?
    end

    it "should not let reservations be made outside the reservation window" do
      pending
    end

    context "schedule rules" do
      before :each do
        @rule.destroy
        @rule_9_to_5 = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => 9, :end_hour => 17, :duration_mins => 15))
        @rule_5_to_7 = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => 17, :end_hour => 19, :duration_mins => 15))
      end
      
      it "should allow a reservation within the schedule rules" do
        
        @reservation = @instrument.reservations.new(:reserve_start_date => Date.today + 1, :reserve_start_hour => 6, :reserve_start_min => 0, :reserve_start_meridian => 'pm', :duration_value => 1, :duration_unit => 'hours')
        @reservation.should be_valid
        @reservation2 = @instrument.reservations.new(:reserve_start_date => Date.today + 1, :reserve_start_hour => 10, :reserve_start_min => 0, :reserve_start_meridian => 'am', :duration_value => 1, :duration_unit => 'hours')
        @reservation2.should be_valid
      end
      it "should not let reservations occur after times defined by schedule rules" do
        @reservation = @instrument.reservations.new(:reserve_start_date => Date.today + 1, :reserve_start_hour => 8, :reserve_start_min => 0, :reserve_start_meridian => 'pm', :duration_value => 1, :duration_unit => 'hours')
        @reservation.should be_invalid
      end
      it "should not let reservations occur before times define by schedule rules" do
        @reservation = @instrument.reservations.new(:reserve_start_date => Date.today + 1, :reserve_start_hour => 5, :reserve_start_min => 0, :reserve_start_meridian => 'am', :duration_value => 1, :duration_unit => 'hours')
        @reservation.should be_invalid
      end
      
      context "schedule rules with restrictions" do
        before :each do
          @user = Factory.create(:user)
          @account = Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
          
          @instrument.update_attributes(:requires_approval => true)
            
          @order = Factory.create(:order, :user => @user, :created_by => @user.id, :account => @account, :facility => @facility)
          @order_detail = Factory.create(:order_detail, :order => @order, :product => @instrument)
          # @instrument.update_attributes(:requires_approval => true)
          
          @restriction_level = @rule_5_to_7.product_access_groups.create(Factory.attributes_for(:product_access_group, :product => @instrument))
          @instrument.reload
          @reservation = Reservation.new(:reserve_start_date => Date.today + 1, 
                                                      :reserve_start_hour => 6, 
                                                      :reserve_start_min => 0, 
                                                      :reserve_start_meridian => 'pm', 
                                                      :duration_value => 1, 
                                                      :duration_unit => 'hours', 
                                                      :order_detail => @order_detail,
                                                      :instrument => @instrument)          
        end
        it "should allow a user to reserve if it doesn't require approval" do
          @instrument.update_attributes(:requires_approval => false)
          @reservation.should be_valid
        end    
        
        it "should not allow a user who is not approved to reserve" do          
          @reservation.should_not be_valid
        end
        it "should not allow a user who is approved, but not in the group" do
          @product_user = ProductUser.create(:user => @user, :product => @instrument, :approved_by => @user.id)
          @product_user.should_not be_new_record
          @reservation.should_not be_valid
        end
        it "should allow a user who is approved and part of the restriction group" do
          @product_user = @user.product_users.create(:product => @instrument, :product_access_group => @restriction_level, :approved_by => @user.id)
          @product_user.should_not be_new_record
          
          @reservation.should be_valid
        end
        
        context "admin overrides" do
          before :each do
            # user is not in the restricted group
            @product_user = ProductUser.create(:user => @user, :product => @instrument, :approved_by => @user.id)
            @admin = Factory.create(:user)
            UserRole.grant(@admin, UserRole::ADMINISTRATOR)
          end

          it "should allow an administrator to save in one of the restricted scheduling rules" do
            @reservation.save_as_user!(@admin)
            # if it raises an exception, we're in trouble            
          end
          it "should not allow a regular user to save in a restricted scheduling rule" do
            lambda { @reservation.save_as_user!(@user) }.should raise_error(ActiveRecord::RecordInvalid)
          end
          it "should not allow an administrator to save outside of scheduling rules" do
            @reservation.update_attributes(:reserve_start_hour => 10)            
            lambda { @reservation.save_as_user!(@admin) }.should raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end
      
    end
  end

  context "get best possible reservation" do
    before do
      PriceGroupProduct.destroy_all

      @user = Factory.create(:user)
      @nupg_pgp=Factory.create(:price_group_product, :product => @instrument, :price_group => @nupg)

      # Setup a price group with an account for this user
      @price_group1 = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @pg1_pgp=Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group1)
      @account1 = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @account_price_group_member1 = AccountPriceGroupMember.create(Factory.attributes_for(:account_price_group_member).merge(:account => @account1, :price_group => @price_group1))

      # Setup a second price groups with another account for this user
      @user_price_group_member = UserPriceGroupMember.create(Factory.attributes_for(:user_price_group_member).merge(:user => @user, :price_group => @nupg))

      # Order against the first account
      @order = Order.create(Factory.attributes_for(:order).merge(:user => @user, :account => @account1, :created_by => @user))
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).merge(:product => @instrument, :order_status => @os_new))

      @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                     :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                     :duration_value => 60, :duration_unit => 'minutes')
      @reservation.order_detail = @order_detail
      @reservation.save
    end

    it "should find the best price policy" do
      @pp_expensive = InstrumentPricePolicy.create(Factory.attributes_for(:instrument_price_policy).merge(:usage_rate => 22, :instrument => @instrument))
      @pp_cheap     = InstrumentPricePolicy.create(Factory.attributes_for(:instrument_price_policy).merge(:usage_rate => 11, :instrument => @instrument))
      @price_group1.price_policies << @pp_expensive
      @nupg.price_policies         << @pp_cheap

      groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
      assert_equal @pp_cheap, @reservation.cheapest_price_policy(groups)
    end

    it "should find the best reservation window" do
      @pp_short = InstrumentPricePolicy.create(Factory.attributes_for(:instrument_price_policy).merge(:instrument_id => @instrument.id))
      @pg1_pgp.reservation_window=30
      assert @pg1_pgp.save
      @pp_long  = InstrumentPricePolicy.create(Factory.attributes_for(:instrument_price_policy).merge(:instrument_id => @instrument.id))
      @nupg_pgp.reservation_window=60
      assert @nupg_pgp.save
      @price_group1.price_policies << @pp_short
      @nupg.price_policies         << @pp_long

      groups = (@order.user.price_groups + @order.account.price_groups).flatten.uniq
      assert_equal @pp_long.reservation_window, @reservation.longest_reservation_window(groups)
    end
  end

  context 'has_actuals?' do
    before :each do
      @reservation = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
                                                     :reserve_start_min => 0, :reserve_start_meridian => 'am',
                                                     :duration_value => 60, :duration_unit => 'minutes')
    end

    it 'should not have actuals' do
      @reservation.should_not be_has_actuals
    end

    it 'should have actuals' do
      @reservation.actual_start_at=Time.zone.now
      @reservation.actual_end_at=Time.zone.now
      @reservation.should be_has_actuals
    end

  end

  context "as_calendar_obj" do
    before :each do
      @reservation = @instrument.reservations.create!(:reserve_start_at => 1.hour.ago,
                                                     :duration_value => 60, :duration_unit => 'minutes')
      @reserve_end_at_timestamp = @reservation.reserve_end_at.strftime("%a, %d %b %Y %H:%M:%S")

      @cal_obj_wo_actual_end = @reservation.as_calendar_object
      @end_time = 5.minutes.from_now
      @reservation.actual_end_at = @end_time
      @cal_obj_w_actual_end = @reservation.as_calendar_object

      @actual_end_at_timestamp = @reservation.actual_end_at.strftime("%a, %d %b %Y %H:%M:%S")

      assert @reservation.reserve_end_at != @reservation.actual_end_at
    end

    it "should have end set to reserve_end_at timestamp if no actual" do
      @cal_obj_wo_actual_end['end'].should == @reserve_end_at_timestamp
    end

    it "should have end set to actual_end_at timestamp" do
      @cal_obj_w_actual_end['end'].should == @actual_end_at_timestamp
    end
  end
end
