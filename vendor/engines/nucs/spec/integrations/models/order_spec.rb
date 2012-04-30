require 'spec_helper'

describe Order do

  context 'add, clear, adjust' do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = Factory.create(:price_group, :facility => @facility)
      @order_status     = Factory.create(:order_status)
      @service          = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_pp       = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @service_same     = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_same_pp  = Factory.create(:service_price_policy, :service => @service_same, :price_group => @price_group)

      @facility2         = Factory.create(:facility)
      @facility_account2 = @facility2.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group2      = Factory.create(:price_group, :facility => @facility2)
      @service2          = @facility2.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account2.id))
      @service2_pp       = Factory.create(:service_price_policy, :service => @service2, :price_group => @price_group2)

      @user            = Factory.create(:user)
      @pg_member       = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account         = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @cart            = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account))
    end

    context 'auto_assign_account!' do
      before :each do
        @facility=Factory.create(:facility)
        place_and_complete_item_order(@user, @facility)
      end

      it 'should assign payment source if user has a valid account and has never placed an order' do
        @nufs=Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
        define_open_account(@item.account, @nufs.account_number)
        @user.reload

        @order.account.should be_nil
        @order.auto_assign_account!(@item)
        @order.account.should == @nufs
      end
      
      it 'should assign payment source if user has an old account that has orders, but a new one that does not' do
        @nufs_inactive=Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}], :suspended_at => 1.day.ago)
        place_and_complete_item_order(@user, @facility, @nufs_inactive)
        @order2 = @order

        @nufs=Factory.create(:nufs_account, :account_users_attributes => [{:user => @user, :created_by => @user, :user_role => 'Owner'}])
        define_open_account(@item.account, @nufs.account_number)

        place_and_complete_item_order(@user, @facility)
        @order3 = @order

        @user.reload

        @order3.account.should be_nil
        @order3.auto_assign_account!(@item)
        @order3.account.should == @nufs
      end

      it 'should raise if an account cannot be found' do
        assert_raise RuntimeError do
          @order.auto_assign_account!(@item)
        end
      end

    end

  end
end
