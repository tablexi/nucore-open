require 'spec_helper'
require 'controller_spec_helper'

require 'stringio'
require 'csv'


CSV_HEADERS = ["Netid / Email", "Chart String" , "Product Name" , "Quantity" , "Order Date" , "Fulfillment Date"]

DEFAULT_ORDER_DATE = 4.days.ago.to_date.strftime("%m/%d/%Y")
DEFAULT_FULLFILLED_DATE = 3.days.ago.to_date.strftime("%m/%d/%Y")
def errors_for_import_with_row(opts={})
  row = CSV::Row.new(CSV_HEADERS, [
    opts[:username]           || @guest.username,
    opts[:account_number]     || "111-2222222-33333333-01",
    opts[:product_name]       || "Example Item",
    opts[:quantity]           || 1,
    opts[:order_date]         || DEFAULT_ORDER_DATE,
    opts[:fullfillment_date]  || DEFAULT_FULLFILLED_DATE
  ])

  errs = @order_import.errors_for(row)
end

describe OrderImport do
  before(:all) { create_users }

  it { should belong_to :creator }
  it { should belong_to :upload_file }
  it { should belong_to :error_file }
  it { should validate_presence_of :upload_file_id }
  it { should validate_presence_of :created_by }
  
  context "behavioral assertions" do
    before :each do
      # clear Timecop's altering of time if active
      Timecop.return
      
      before_import = 10.days.ago
      Timecop.travel(before_import) do
        @authable         = Factory.create(:facility)
        @facility_account = @authable.facility_accounts.create!(Factory.attributes_for(:facility_account))
        
        grant_role(@guest, @authable)
        grant_role(@director, @authable)
        @item             = @authable.items.create!(Factory.attributes_for(:item,
          :facility_account_id => @facility_account.id,
          :name => "Example Item"
        ))

        # price stuff
        @price_group      = @authable.price_groups.create!(Factory.attributes_for(:price_group))
        @pg_member        = Factory.create(:user_price_group_member, :user => @guest, :price_group => @price_group)
        @item_pp=@item.item_price_policies.create!(Factory.attributes_for(:item_price_policy,
          :price_group_id => @price_group.id,
        ))
        @account          = Factory.create(:nufs_account,
          :description => "dummy account",
          :account_number => '111-2222222-33333333-01',
          :account_users_attributes => [Hash[:user => @guest, :created_by => @guest, :user_role => 'Owner']]
        )
      end
      
      stored_file = StoredFile.create!(
        :file => StringIO.new("c,s,v"),
        :file_type => 'import_upload',
        :name => "clean_import.csv",
        :created_by => @director.id
      )
      
      @order_import=OrderImport.create!(
        :created_by => @director.id,
        :upload_file => stored_file,
        :facility => @authable
      )
    end

    describe "error detection" do
      it "should import a valid row" do
        errors_for_import_with_row.should == []
      end

      it "should have error when user isn't found" do
        errors_for_import_with_row(:username => "username_that_wont_be_there").first.should match /user/
      end

      it "should have error when account isn't found" do
        errors_for_import_with_row(:account_number => "not_an_account_number").first.should match /find account/
      end

      it "should have error when product isn't found" do
        errors_for_import_with_row(:product_name => "not_a_product_name").first.should match /find product/
      end
    end

    context "created order" do
      before :each do
        # run the import of row
        errors_for_import_with_row.should == []

        @created_order = Order.last
      end

      it "should have ordered_at set appropriately" do
        @created_order.ordered_at.strftime("%m/%d/%Y").should == DEFAULT_ORDER_DATE
      end

      it "should have created_by_user set to creator of import" do
        @created_order.created_by_user.should == @director
      end

      it "should have user set to user in line of import" do
        @created_order.user.should == @guest
      end

      it "should have state 'purchased'" do
        @created_order.should be_purchased
      end

      context "created order_details" do
        it "should exist" do
          assert @created_order.has_details?
        end

        it "should have the right product" do
          @created_order.order_details.first.product.should == @item
        end

        it "should have status complete" do
          @created_order.order_details.each do |od|
            od.state.should == "complete"
          end
        end

        it "should have price policies" do
          @created_order.order_details.each do |od|
            od.price_policy.should_not be nil
          end
        end

        it "should not be problem orders" do
          @created_order.order_details.each do |od|
            od.should_not be_problem_order
          end
        end

        it "should have right fullfilled_at" do
          @created_order.order_details.each do |od|
            od.fulfilled_at.strftime("%m/%d/%Y").should == DEFAULT_FULLFILLED_DATE
          end
        end
      end
    end
    
    it "should merge orders when possible" do
      lambda {
        # import two identical rows
        errors_for_import_with_row.should == []
        errors_for_import_with_row.should == []
      }.should change(Order, :count).from(0).to(1)
    end
  end
end
