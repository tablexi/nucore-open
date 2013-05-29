require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrderDetailsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @facility_account=FactoryGirl.create(:facility_account, :facility => @authable)
    @product=FactoryGirl.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner :director
    @order=FactoryGirl.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now,
      :state => 'purchased'
    )
    @price_group=FactoryGirl.create(:price_group, :facility => @authable)
    @price_policy=FactoryGirl.create(:item_price_policy, :product => @product, :price_group => @price_group)
    @order_detail=FactoryGirl.create(:order_detail, :order => @order, :product => @product, :price_policy => @price_policy)
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
      expect(assigns(:in_open_journal)).to_not be_nil
      should render_template 'edit'
    end

    it_should_allow :staff, 'to acknowledge order detail is part of open journal' do
      assigns[:in_open_journal].should == true
      assigns[:can_be_reconciled].should == false
      flash[:notice].should be_present
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

    context 'enable/disable subsidy field' do
      def sign_in_and_do_request
        maybe_grant_always_sign_in :director
        do_request
        @dom = Nokogiri::HTML(response.body)
      end
      context 'new' do
        before :each do
          @order_detail.update_attributes(:price_policy => nil)
          Item.any_instance.stub(:cheapest_price_policy).and_return(@price_policy)
          @order_detail.assign_estimated_price!
          @order_detail.estimated_cost.should be
          sign_in_and_do_request
        end

        it 'should say "Estimated Subsidy"' do
          response.body.to_s.should =~ /Estimated\sSubsidy/
        end

        it 'should not have a field for subsidy' do
          @dom.css('.order_detail_edit .estimated_subsidy').should_not be_empty
          @dom.css('.order_detail_edit .actual_subsidy input').should be_empty
        end

        it 'should have the estimated price and subsidy' do
          @dom.css('.order_detail_edit .estimated_cost').first.content.should == '$1.00'
          @dom.css('.order_detail_edit .estimated_subsidy').first.content.should == '$0.00'
        end
      end

      context "no price policy assigned" do
        before :each do
          @order_detail.update_attributes(:price_policy => nil, :actual_cost => nil, :estimated_cost => nil)
          sign_in_and_do_request
        end

        it 'should say "Estimated Subsidy"' do
          response.body.should_not =~ /Estimated\sSubsidy/
        end

        it 'should say "Unassigned"' do
          @dom.css('.order_detail_edit .unassigned_subsidy').first.content.should == 'Unassigned'
        end

        it 'should not have a field for subsidy' do
          @dom.css('.order_detail_edit .actual_subsidy input').should be_empty
        end
      end

      context 'price policy without subsidy' do
        context 'instrument' do
          before :each do
            prepare_reservation
            sign_in_and_do_request
          end

          it 'should be set up correctly' do
            @order_detail.price_policy.should == @instrument_price_policy
            @order_detail.actual_cost.should be
            @order_detail.actual_subsidy.should be
          end

          it 'should include the price policy name' do
            @dom.css('.order_detail_edit .subsidy_header').first.content.should include @instrument_price_policy.price_group.name
          end

          it 'should have the field disabled' do
            @dom.css('.order_detail_edit .actual_subsidy input').first.should be_matches '[disabled]'
          end
        end
        context 'item' do
          before :each do
            @price_policy.update_attributes(:unit_cost => 10, :unit_subsidy => 0)
            @order_detail.change_status!(OrderStatus.complete.first)
            sign_in_and_do_request
          end
          it 'should include the price policy name' do
            @dom.css('.order_detail_edit .subsidy_header').first.content.should include @price_policy.price_group.name
          end
          it 'should have the field disabled' do
            @dom.css('.order_detail_edit .actual_subsidy input').first.should be_matches '[disabled]'
          end
        end
      end

      context 'price_policy with subsidy' do
        context 'instrument' do
          before :each do
            prepare_reservation
            @instrument_price_policy.update_attributes(:usage_subsidy => 1)
            sign_in_and_do_request
          end

          it 'should include the price policy name' do
            @dom.css('.order_detail_edit .subsidy_header').first.content.should include @instrument_price_policy.price_group.name
          end
          it 'should have the field enabled' do
            @dom.css('.order_detail_edit .actual_subsidy input').first.should_not be_matches '[disabled]'
          end
        end
        context 'item' do
          before :each do
            @price_policy.update_attributes(:unit_cost => 10, :unit_subsidy => 1)
            @order_detail.change_status!(OrderStatus.complete.first)
            sign_in_and_do_request
          end
          it 'should include the price policy name' do
            @dom.css('.order_detail_edit .subsidy_header').first.content.should include @price_policy.price_group.name
          end
          it 'should have the field enabled' do
            @dom.css('.order_detail_edit .actual_subsidy input').first.should_not be_matches '[disabled]'
          end
        end
      end
    end

  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
    end

    it_should_allow_operators_only


    context 'from summary' do
      before :each do
        @path=edit_facility_order_path(@authable, @order)
        @params[:return_to]=@path
        @params[:order_detail]={
          :order_status_id => OrderStatus.new_os.first.id,
          :actual_cost => '5.0',
          :actual_subsidy => '0',
          :reconciled_note => '',
          :account_id => @account.id.to_s
        }
      end

      it_should_allow :director, 'to go back to order summary' do
        assert_redirected_to @path
      end
    end


    context 'cancel reservation' do
      before :each do
        start_date=Time.zone.now+1.day
        setup_reservation @authable, @facility_account, @account, @director
        place_reservation @authable, @order_detail, start_date
        @instrument.update_attribute :min_cancel_hours, 25
        InstrumentPricePolicy.all.each{|pp| pp.update_attribute :cancellation_cost, 5.0}
        FactoryGirl.create :user_price_group_member, :user_id => @director.id, :price_group_id => @price_group.id

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
        OrderDetail.any_instance.stub(:save!).and_raise(ActiveRecord::RecordInvalid)
        do_request
        response.should render_template :edit
        flash[:error].should be_present
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


  context 'destroy' do
    before :each do
      @method=:delete
      @action=:destroy
    end

    it_should_allow_operators_only :redirect do
      flash[:notice].should be_present
      @order_detail.reload.should_not be_frozen
      assert_redirected_to edit_facility_order_path(@authable, @order)
    end

    context 'merge order' do
      before :each do
        @clone=@order.dup
        assert @clone.save
        @order.update_attribute :merge_with_order_id, @clone.id
      end

      it_should_allow :director, 'to destroy a detail that is part of a merge order' do
        assert_raises(ActiveRecord::RecordNotFound) { OrderDetail.find @order_detail.id }
        flash[:notice].should be_present
        assert_redirected_to edit_facility_order_path(@authable, @clone)
      end
    end
  end

  def prepare_reservation
    @order_detail.update_attributes(:price_policy => nil)
    @instrument = FactoryGirl.create(:instrument, :facility => @authable,
      :facility_account => @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account)))
    @instrument_price_policy=FactoryGirl.create(:instrument_price_policy,
                                            :product => @instrument,
                                            :price_group => @price_group,
                                            :usage_rate => 10,
                                            :usage_subsidy => 0)
    @instrument_price_policy.should be_persisted
    puts @instrument_price_policy.errors.full_messages
    Instrument.any_instance.stub(:cheapest_price_policy).and_return(@instrument_price_policy)
    @reservation = place_reservation @authable, @order_detail, 1.day.ago
    @order_detail.backdate_to_complete! @reservation.reserve_end_at
  end

end
