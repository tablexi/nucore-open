require 'spec_helper'

describe Statement do
  before :each do
    @facility=FactoryGirl.create(:facility)
    @user=FactoryGirl.create(:user)
    @account=FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
  end

  it "can be created with valid attributes" do
    @statement = Statement.create({:facility => @facility, :created_by => 1, :account => @account})
    @statement.should be_valid
  end

  context "finalized_at" do
    before :each do
      @facility  = FactoryGirl.create(:facility)
      @statement = Statement.create({:facility => @facility, :created_by => 1})
    end
  end

  it "requires created_by" do
    @statement = Statement.new({:created_by => nil})
    @statement.should_not be_valid
    @statement.errors[:created_by].should_not be_nil

    @statement = Statement.new({:created_by => 1})
    @statement.valid?
    @statement.errors[:created_by].should be_empty
  end

  it "requires a facility" do
    @statement = Statement.new({:facility_id => nil})
    @statement.should_not be_valid
    @statement.errors[:facility_id].should_not be_nil

    @statement = Statement.new({:facility_id => 1})
    @statement.valid?
    @statement.errors[:facility_id].should be_empty
  end

  context 'with order details' do
    before :each do
      @statement = Statement.create({:facility => @facility, :created_by => 1, :account => @account})
      @order_details = []
      3.times do
        @order_details << place_and_complete_item_order(@user, @facility, @account, true)
        # @item is set by place_and_complete_item_order, so we need to define it as open
        # for each one
        define_open_account(@item.account, @account.account_number)
      end
      @order_details.each { |od| @statement.add_order_detail(od) }
    end

    context 'with the ordered_at switched up' do
      before :each do
        @order_details[0].order.update_attributes(:ordered_at => 2.days.ago)
        @order_details[1].order.update_attributes(:ordered_at => 3.days.ago)
        @order_details[2].order.update_attributes(:ordered_at => 1.day.ago)
      end
      it 'should return the first date' do
        @statement.first_order_detail_date.should == @order_details[1].ordered_at
      end
    end

    it 'should set the statement_id of each order detail' do
      @order_details.each { |od| od.statement_id.should_not be_nil }
    end

    it 'should have 3 order_details' do
      @statement.order_details.size.should == 3
    end

    it 'should have 3 rows' do
      @statement.statement_rows.size.should == 3
    end

    it 'should not be reconciled' do
      @statement.should_not be_reconciled
    end

    context 'with one order detail reconciled' do
      before :each do
        @order_details.first.to_reconciled!
      end

      it 'should not be reconciled' do
        @statement.should_not be_reconciled
      end
    end

    context 'with all order_details reconciled' do
      before :each do
        @order_details.each { |od| od.to_reconciled! }
      end

      it 'should be reconciled' do
        @statement.should be_reconciled
      end
    end
  end
end
