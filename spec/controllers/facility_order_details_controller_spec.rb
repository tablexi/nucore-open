require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrderDetailsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner :director
    @order=Factory.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now,
      :state => 'purchased'
    )
    @price_group=Factory.create(:price_group, :facility => @authable)
    @price_policy=Factory.create(:item_price_policy, :product => @product, :price_group => @price_group)
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product, :price_policy => @price_policy)
    @order_detail.set_default_status!
    @params={ :facility_id => @authable.url_name, :order_id => @order.id, :id => @order_detail.id }
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
      @journal=Journal.new(:facility => @authable, :created_by => 1, :updated_by => 1, :reference => 'xyz', :journal_date => Time.zone.now)
      assert @journal.save
      @order_detail.journal=@journal
      assert @order_detail.save
    end

    it_should_allow_operators_only do
      assigns[:can_be_reconciled].should == false
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      should assign_to :in_open_journal
      should render_template 'edit'
    end

    it_should_allow :staff, 'to acknowledge order detail is part of open journal' do
      assigns[:in_open_journal].should == true
      assigns[:can_be_reconciled].should == false
      should set_the_flash
    end

    it 'should acknowledge order detail is not part of open journal and is reconcilable' do
      @journal.is_successful=true
      assert @journal.save
      @order_detail.account=@account
      assert @order_detail.save
      @order_detail.to_complete!
      maybe_grant_always_sign_in :staff
      do_request
      assigns[:in_open_journal].should == false
      assigns[:can_be_reconciled].should == true
      should_not set_the_flash
    end

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
    end

    it_should_allow_operators_only

    context 'cancel reservation' do
      before :each do
        start_date=Time.zone.now+1.day
        setup_reservation @authable, @facility_account, @account, @director
        place_reservation @authable, @order_detail, start_date
        @instrument.update_attribute :min_cancel_hours, 25
        InstrumentPricePolicy.all.each{|pp| pp.update_attribute :cancellation_cost, 5.0}
        Factory.create :user_price_group_member, :user_id => @director.id, :price_group_id => @price_group.id

        @params[:order_id]=@order.id
        @params[:id]=@order_detail.id
        @params[:order_detail]={
          :order_status_id => OrderStatus.cancelled.first.id,
          :actual_cost => '5.0',
          :actual_subsidy => '0',
          :reconciled_note => '',
          :account_id => @account.id.to_s
        }
      end

      it 'should add cancellation fee' do
        @params.merge! :with_cancel_fee => '1'
        maybe_grant_always_sign_in :director
        do_request
        @order_detail.reload.state.should == 'complete'
        @order_detail.actual_cost.should == @order_detail.price_policy.cancellation_cost
      end

      it 'should not add cancellation fee' do
        @params.merge! :with_cancel_fee => '0'
        maybe_grant_always_sign_in :director
        do_request
        @order_detail.reload.state.should == 'cancelled'
      end
      it 'should render edit on failure' do
        maybe_grant_always_sign_in :director
        OrderDetail.any_instance.stubs(:save!).raises(ActiveRecord::RecordInvalid)
        do_request
        response.should render_template :edit
        should set_the_flash
      end
      it 'should redirect to timeline view on success' do
        maybe_grant_always_sign_in :director
        do_request
        response.should redirect_to timeline_facility_reservations_path
      end
    end

  end


  context 'resolve_dispute' do

    before :each do
      @method=:post
      @action=:resolve_dispute
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_reason='got charged too much'
      assert @order_detail.save
      @params[:order_detail_id]=@params[:id]
      @params.delete(:id)
    end

    it_should_require_login

    it_should_allow :staff do
      # abuse of API since we're not expecting success
      should render_template('404')
    end

    it_should_allow_all facility_managers do
      should respond_with :success
    end

  end


  context 'new_price' do

    before :each do
      @method=:get
      @action=:new_price
      @params[:order_detail_id]=@params[:id]
      @params.delete(:id)
    end

    it_should_allow_operators_only

  end


  context 'remove_from_journal' do

    before :each do
      @method=:get
      @action=:remove_from_journal
      @journal=Journal.new(:facility => @authable, :created_by => 1, :updated_by => 1, :reference => 'xyz', :journal_date => Time.zone.now)
      assert @journal.save
      @order_detail.journal=@journal
      assert @order_detail.save
    end

    it_should_allow_operators_only :redirect do
      @order_detail.reload.journal.should be_nil
      should set_the_flash
      assert_redirected_to edit_facility_order_order_detail_path(@authable, @order_detail.order, @order_detail)
    end

  end

end