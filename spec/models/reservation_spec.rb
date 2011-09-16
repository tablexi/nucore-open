require 'spec_helper'

describe Reservation do
  before(:each) do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    # add rule, available every day from 12 am to 5 pm, 60 minutes duration
    @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(:start_hour => 0, :end_hour => 17))
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

    it "should not let reservations occur outside of times/days defined by schedule rules" do
      pending
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

end
