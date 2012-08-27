require 'spec_helper'; require 'controller_spec_helper'

describe FacilityOrdersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner
    @order_detail = place_product_order(@director, @authable, @product, @account)
    @order_detail.order.update_attributes!(:state => 'purchased')
    @params={ :facility_id => @authable.url_name }
  end

  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only {}

    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      ['order_number','date', 'product', 'assigned_to', 'status'].each do |sort|
        it "should not blow up for sort by #{sort}" do
          @params[:sort] = sort
          do_request
          response.should be_success          
          assigns[:order_details].should_not be_nil
          assigns[:order_details].first.should_not be_nil
        end
      end

      it 'should not return reservations' do
        # setup_reservation overwrites @order_detail
        @order_detail_item = @order_detail
        @order_detail_reservation = setup_reservation(@authable, @facility_account, @account, @director)
        @reservation = place_reservation(@authable, @order_detail_reservation, Time.zone.now + 1.hour)

        @authable.reload.order_details.should contain_all [@order_detail_item, @order_detail_reservation]
        do_request
        assigns[:order_details].should == [@order_detail_item]
      end
    end
  end


  context 'edit' do

    before :each do
      @method=:get
      @action=:edit
      @params.merge!(:id => @order.id)
    end

    it_should_require_login

    it_should_allow_all facility_operators do
      assigns(:order).should == @order
      should render_template 'edit'
    end

  end


  context 'batch_update' do

    before :each do
      @method=:post
      @action=:batch_update
    end

    it_should_allow_operators_only :redirect

  end


  context 'show_problems' do

    before :each do
      @method=:get
      @action=:show_problems
    end

    it_should_allow_managers_only

  end


  context 'disputed' do

    before :each do
      @method=:get
      @action=:disputed
    end

    it_should_allow_operators_only

  end


  context 'update' do
    before :each do
      @method=:put
      @action=:update
      @params.merge!({
        :id => @order.id,
        :product_add => @product.id,
        :product_add_quantity => 0
      })
    end

    it_should_allow_operators_only :redirect, 'to submit product quantity 0 and get failure notice' do
      flash[:notice].should be_present
      assert_redirected_to edit_facility_order_path(@authable, @order)
    end

    context 'with quantity' do
      before :each do
        @params[:product_add_quantity]=1
        @order.order_details.each{|od| od.destroy }
      end

      it_should_allow :director, 'to add an item to existing order directly' do
        assert_no_merge_order @order, @product
      end

      context 'with instrument' do
        before :each do
          options=Factory.attributes_for(:instrument, :facility_account => @facility_account, :min_reserve_mins => 60, :max_reserve_mins => 60)
          @instrument=@authable.instruments.create(options)
          @params[:product_add]=@instrument.id
        end

        it_should_allow :director, 'to add an instrument to existing order via merge' do
          assert_merge_order @order, @instrument
        end
      end

      context 'with service' do
        before :each do
          @service=@authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
          @params[:product_add]=@service.id
        end

        context 'with active survey' do
          before :each do
            Service.any_instance.stubs(:active_survey?).returns(true)
            Service.any_instance.stubs(:active_template?).returns(false)
            OrderDetail.any_instance.stubs(:valid_service_meta?).returns(false)
          end

          it_should_allow :director, 'to add a service to existing order via merge' do
            assert_merge_order @order, @service
          end
        end

        context 'with active template' do
          before :each do
            Service.any_instance.stubs(:active_survey?).returns(false)
            Service.any_instance.stubs(:active_template?).returns(true)
            OrderDetail.any_instance.stubs(:valid_service_meta?).returns(false)
          end

          it_should_allow :director, 'to add an service to existing order via merge' do
            assert_merge_order @order, @service
          end
        end

        context 'with nothing active' do
          before :each do
            Service.any_instance.stubs(:active_survey?).returns(false)
            Service.any_instance.stubs(:active_template?).returns(false)
          end

          it_should_allow :director, 'to add an service to existing order directly' do
            assert_no_merge_order @order, @service
          end
        end
      end

      context 'with bundle' do
        before :each do
          @bundle=@authable.bundles.create(Factory.attributes_for(:bundle, :facility_account_id => @facility_account.id))
          @params[:product_add]=@bundle.id
          BundleProduct.create!(:bundle => @bundle, :product => @product, :quantity => 1)
        end

        context 'has items' do
          before :each do
            item=Factory.create(:item, :facility_account => @facility_account, :facility => @authable)
            BundleProduct.create!(:bundle => @bundle, :product => item, :quantity => 1)
          end

          it_should_allow :director, 'to add an item to existing order directly' do
            assert_no_merge_order @order, @bundle, 2
          end
        end

        context 'has instrument' do
          before :each do
            options=Factory.attributes_for(:instrument, :facility_account => @facility_account, :min_reserve_mins => 60, :max_reserve_mins => 60)
            @instrument=@authable.instruments.create(options)
            BundleProduct.create!(:bundle => @bundle, :product => @instrument, :quantity => 1)
          end

          it_should_allow :director, 'to add an instrument to existing order via merge' do
            assert_merge_order @order, @bundle, 1, 1
          end
        end

        context 'has service' do
          before :each do
            @service=@authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
            BundleProduct.create!(:bundle => @bundle, :product => @service, :quantity => 1)
          end

          context 'with active survey' do
            before :each do
              Service.any_instance.stubs(:active_survey?).returns(true)
              Service.any_instance.stubs(:active_template?).returns(false)
              OrderDetail.any_instance.stubs(:valid_service_meta?).returns(false)
            end

            it_should_allow :director, 'to add a bundle to existing order via merge' do
              assert_merge_order @order, @bundle, 1, 1
            end
          end

          context 'with active template' do
            before :each do
              Service.any_instance.stubs(:active_survey?).returns(false)
              Service.any_instance.stubs(:active_template?).returns(true)
              OrderDetail.any_instance.stubs(:valid_service_meta?).returns(false)
            end

            it_should_allow :director, 'to add a bundle to existing order via merge' do
              assert_merge_order @order, @bundle, 1, 1
            end
          end

          context 'with nothing active' do
            before :each do
              Service.any_instance.stubs(:active_survey?).returns(false)
              Service.any_instance.stubs(:active_template?).returns(false)
            end

            it_should_allow :director, 'to add a bundle to existing order directly' do
              assert_no_merge_order @order, @bundle, 2
            end
          end
        end
      end
    end

    def assert_update_success order, product
      if product.is_a? Bundle
        order.order_details.each do |od|
          od.order_status.should == OrderStatus.default_order_status
          product.products.should be_include(od.product)
        end
      else
        order_detail=order.order_details[0]
        order_detail.product.should == product
        order_detail.order_status.should == OrderStatus.default_order_status
      end

      flash[:notice].should be_present
      assert_redirected_to edit_facility_order_path(@authable, order.to_be_merged? ? order.merge_order : order)
    end

    def assert_no_merge_order original_order, product, detail_count=1
      original_order.reload.order_details.size.should == detail_count
      assert_update_success original_order, product
    end

    def assert_merge_order original_order, product, detail_count=1, original_detail_count=0
      original_order.reload.order_details.size.should == original_detail_count
      merges=Order.where(:merge_with_order_id => original_order.id).all
      merges.size.should == 1
      merge_order=merges[0]
      merge_order.merge_order.should == original_order
      merge_order.facility_id.should == original_order.facility_id
      merge_order.account_id.should == original_order.account_id
      merge_order.user_id.should == original_order.user_id
      merge_order.created_by.should == @director.id
      merge_order.ordered_at.should_not be_blank
      merge_order.order_details.size.should == detail_count
      MergeNotification.count.should == detail_count
      assert_update_success merge_order, product
    end

  end


  context 'tab_counts' do
    before :each do
      @method = :get
      @action = :tab_counts
      @order_detail2=Factory.create(:order_detail, :order => @order, :product => @product)
      
      @authable.order_details.non_reservations.new_or_inprocess.size.should == 2

      @problem_order_details = (1..3).map do |i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes(:price_policy_id => nil)
        order_detail
      end
      

      @disputed_order_details = (1..4).map do |i|
        order_detail = place_and_complete_item_order(@staff, @authable)
        order_detail.update_attributes({
          :dispute_at => Time.zone.now,
          :dispute_resolved_at => nil,
          :dispute_reason => 'because'
        })
        order_detail
      end
      @authable.order_details.in_dispute.size.should == 4

      @params.merge!(:tabs => ['new_or_in_process_orders', 'disputed_orders', 'problem_orders'])
    end

    it_should_allow_operators_only {}
    
    context 'signed in' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it 'should get only new if thats all you ask for' do
        @authable.order_details.non_reservations.new_or_inprocess.to_sql
        @params[:tabs] = ['new_or_in_process_orders']
        do_request
        response.should be_success
        body = JSON.parse(response.body)
        body.keys.should contain_all ['new_or_in_process_orders']
        body['new_or_in_process_orders'].should == 2
      end

      it 'should get everything if you ask for it' do
        do_request
        response.should be_success
        body = JSON.parse(response.body)
        body.keys.should contain_all ['new_or_in_process_orders', 'disputed_orders', 'problem_orders']
        body['new_or_in_process_orders'].should == 2
        body['problem_orders'].should == 3
        body['disputed_orders'].should == 4
      end
    end
  end

end
