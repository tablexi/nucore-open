require 'spec_helper'
describe OrderDetailObserver do
  module DummyHooks
    class DummyHook1
      attr_accessor :settings
    end
    class DummyHook2; end
    class DummyHook3; end
  end

  context 'status change hooks' do
    # This before and after all is some nastiness to use a specific file for these tests, but
    # keep the original Settings for all other tests.
    before :all do
      Settings.reload_from_files(Rails.root.join("spec", "support", "order_detail_status_change_notification_test.yaml"))
    end

    after :all do
      Settings.reload_from_files(
        Rails.root.join("config", "settings.yml").to_s,
        Rails.root.join("config", "settings", "#{Rails.env}.yml").to_s,
        Rails.root.join("config", "environments", "#{Rails.env}.yml").to_s
      )
    end
    
    before :each do
      @hooks = OrderDetailObserver.send(:status_change_hooks)
    end

    it 'should support a list' do
      @hooks[:list_with_duplicates].size.should == 2
    end
    it 'should support a list with duplicates' do
      @hooks[:list_with_duplicates].map(&:class).should == [DummyHooks::DummyHook1, DummyHooks::DummyHook1]
    end
    it 'should support settings' do
      @hooks[:item_with_settings].size.should == 1
      @hooks[:item_with_settings].first.settings[:setting_1].should == 'test'
      @hooks[:item_with_settings].first.settings[:setting_2].should == 'test2'
    end
    it 'should support a single class' do
      @hooks[:single_class].size.should == 1
      @hooks[:single_class].first.should be_kind_of DummyHooks::DummyHook3
    end
    it 'should support simple array' do
      @hooks[:simple_array].size.should == 2
      @hooks[:simple_array].map(&:class).should == [DummyHooks::DummyHook1, DummyHooks::DummyHook2]
    end    
  end

  context 'order details changes statuses' do
    before :each do
      Settings.reload!
      Settings.order_details.status_change_hooks = nil
      @facility = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user     = Factory.create(:user)
      @item     = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item.should be_valid
      Factory.create :item_price_policy, :product => @item, :price_group => PriceGroup.base.first
      @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      define_open_account(@item.account, @account.account_number)
      @order    = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @order_detail.state.should == 'new'
      @order_detail.version.should == 1
      @order_detail.order_status.should be_nil
    
      @order.validate_order!.should be_true
      @order.purchase!.should be_true
      
      @order_detail.reload.order.state.should == 'purchased'

      Settings.order_details.status_change_hooks = {:in_process => 'DummyHooks::DummyHook1', :new => 'DummyHooks::DummyHook2'}
      @order_detail.order_status.should == OrderStatus.new_os.first
    end
    it 'should trigger a notification on change to inprogress' do
      DummyHooks::DummyHook1.any_instance.expects(:on_status_change).once.with(@order_detail, OrderStatus.new_os.first, OrderStatus.inprocess.first).once
      @order_detail.change_status!(OrderStatus.inprocess.first).should be_true
    end
    it 'should trigger a notification on change from in_process to new' do
      DummyHooks::DummyHook1.any_instance.expects(:on_status_change).once.with(@order_detail, OrderStatus.new_os.first, OrderStatus.inprocess.first)
      @order_detail.change_status!(OrderStatus.inprocess.first).should be_true
      DummyHooks::DummyHook2.any_instance.expects(:on_status_change).once.with(@order_detail, OrderStatus.inprocess.first, OrderStatus.new_os.first)
      @order_detail.change_status!(OrderStatus.new_os.first).should be_true
    end
    it 'should not trigger going from new to new' do
      DummyHooks::DummyHook2.any_instance.expects(:on_status_change).never
      @order_detail.change_status!(OrderStatus.new_os.first).should be_true
    end
  end
end
