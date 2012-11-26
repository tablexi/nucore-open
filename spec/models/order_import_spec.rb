require 'spec_helper'
require 'controller_spec_helper'

require 'stringio'
require 'csv_helper'

include CSVHelper
CSV_HEADERS = ["Netid / Email", "Chart String" , "Product Name" , "Quantity" , "Order Date" , "Fulfillment Date"]

DEFAULT_ORDER_DATE = 4.days.ago.to_date
DEFAULT_FULLFILLED_DATE = 3.days.ago.to_date

def errors_for_import_with_row(opts={})
  row = CSV::Row.new(CSV_HEADERS, [
    opts[:username]           || @guest.username,
    opts[:account_number]     || "111-2222222-33333333-01",
    opts[:product_name]       || "Example Item",
    opts[:quantity]           || 1,
    opts[:order_date]         || DEFAULT_ORDER_DATE.strftime("%m/%d/%Y"),
    opts[:fullfillment_date]  || DEFAULT_FULLFILLED_DATE.strftime("%m/%d/%Y")
  ])

  errs = @order_import.errors_for(row)
end

describe OrderImport do
  before(:all) do
    create_users
  end

  before :each do
    # clear Timecop's altering of time if active
    Timecop.return
    
    before_import = 10.days.ago
    Timecop.travel(before_import) do
      @authable         = Factory.create(:facility)
      @facility_account = @authable.facility_accounts.create!(Factory.attributes_for(:facility_account))
      
      grant_role(@director, @authable)
      @item             = @authable.items.create!(Factory.attributes_for(:item,
        :facility_account_id => @facility_account.id,
        :name => "Example Item"
      ))

      # price stuff
      @price_group      = @authable.price_groups.create!(Factory.attributes_for(:price_group))
      @pg_member        = Factory.create(:user_price_group_member, :user => @guest, :price_group => @price_group)
      @item_pp=@item.item_price_policies.create!(Factory.attributes_for(:item_price_policy,
        :price_group_id => @price_group.id
      ))

      @guest2 = Factory.create :user, :username => 'guest2'
      @pg_member        = Factory.create(:user_price_group_member, :user => @guest2, :price_group => @price_group)
      @account          = Factory.create(:nufs_account,
        :description => "dummy account",
        :account_number => '111-2222222-33333333-01',
        :account_users_attributes => [
          Hash[:user => @guest, :created_by => @guest, :user_role => 'Owner'],
          Hash[:user => @guest2, :created_by => @guest, :user_role => 'Purchaser']
        ]
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
  
  
  # validation testing
  it { should belong_to :creator }
  it { should belong_to :upload_file }
  it { should belong_to :error_file }
  it { should validate_presence_of :upload_file_id }
  it { should validate_presence_of :created_by }
  
  describe "errors_for(row) (low-level) behavior" do

    describe "error detection" do
      it "shouldn't have errors for a valid row" do
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

      it "should handle bad order_date" do
        errors_for_import_with_row(:order_date => "02/31/2012")
      end

      it "should handle bad fullfillment_date" do
        errors_for_import_with_row(:fullfillment_date => "02/31/2012")
      end
    end

    describe "created order" do
      before :each do
        # run the import of row
        errors_for_import_with_row.should == []

        @created_order = Order.last
      end

      it "should have ordered_at set appropriately" do
        @created_order.ordered_at.to_date.should == DEFAULT_ORDER_DATE
      end

      it "should have created_by_user set to creator of import" do
        @created_order.created_by_user.should == @director
      end

      it "should have user set to user in line of import" do
        @created_order.user.should == @guest
      end

      it { @created_order.should be_purchased }

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
            od.fulfilled_at.to_date.should == DEFAULT_FULLFILLED_DATE
          end
        end
      end
    end
    
    describe "multiple calls (same order_key)" do
      before :each do
        @old_count = Order.count
        errors_for_import_with_row(
          :fullfillment_date => 2.days.ago,
          :quantity => 2
        ).should == []
        @first_od = OrderDetail.last
        errors_for_import_with_row(
          :fullfillment_date => 3.days.ago,
          :quantity => 3
        ).should == []
      end
      it "should merge orders when possible" do
        (Order.count - @old_count).should == 1
      end

      it "should not have problem orders" do
        Order.last.order_details.each do |od|
          od.should_not be_problem_order
        end
      end

      it "should not change already attached details" do
        @after_od = OrderDetail.find(@first_od.id)
        @after_od.reload

        @after_od.should == @first_od
      end

    end

    describe "multiple calls (diff order_key)" do
      before :each do
        @old_count = Order.count
        errors_for_import_with_row(
          :fullfillment_date => 2.days.ago,
          :quantity => 2,
          :username => 'guest'
        ).should == []
        @first_od = OrderDetail.last
        errors_for_import_with_row(
          :fullfillment_date => 3.days.ago,
          :quantity => 3,
          :username => 'guest2'
        ).should == []
      end

      it "should not merge when users are different" do
        (Order.count - @old_count).should > 1
      end

      it "should not have problem orders" do
        Order.last.order_details.each do |od|
          od.should_not be_problem_order
        end
      end

      it "should not change already attached details" do
        @after_od = OrderDetail.find(@first_od.id)
        @after_od.reload

        @after_od.should == @first_od
      end
    end
  end

def generate_import_file(*args)
  args = [{}] if args.length == 0 # default to at least one valid row

  whole_csv = CSV.generate :headers => true do |csv|
    csv << CSV_HEADERS
    args.each do |opts|
      row = CSV::Row.new(CSV_HEADERS, [
        opts[:username]           || 'guest',
        opts[:account_number]     || "111-2222222-33333333-01",
        opts[:product_name]       || "Example Item",
        opts[:quantity]           || 1,
        opts[:order_date]         || DEFAULT_ORDER_DATE.strftime("%m/%d/%Y"),
        opts[:fullfillment_date]  || DEFAULT_FULLFILLED_DATE.strftime("%m/%d/%Y")
      ])
      csv << row
    end
  end

  return StringIO.new whole_csv
end
  
  describe "high-level calls" do
    it "should send notifications (save clean orders mode)" do
      import_file = generate_import_file(
        {:order_date => DEFAULT_ORDER_DATE}, # valid rows
        {:order_date => DEFAULT_ORDER_DATE},
        
        
        # diff order date (so will be diff order)
        {
          :order_date => DEFAULT_ORDER_DATE + 1.day,
          :product_name => "Invalid Item Name"
        }
      )
      @order_import.send_receipts = true
      @order_import.upload_file.file = import_file
      @order_import.upload_file.save!
      @order_import.save!

      # expectations
      Notifier.expects(:order_receipt).once.returns( stub({:deliver => nil }) )

      # run the import
      @order_import.process!
    end

    it "should not send notifications if error occured (save nothing on error mode)" do
      import_file = generate_import_file(
        {},
        {:product_name => "Invalid Item Name"}
      )
      @order_import.send_receipts = true
      @order_import.fail_on_error = true
      @order_import.upload_file.file = import_file
      @order_import.upload_file.save!
      @order_import.save!

      # expectations
      Notifier.expects(:order_receipt).never

      # run the import
      @order_import.process!
    end

    it "should send notifications if no errors occured (save nothing on error mode)" do
      import_file = generate_import_file(
        {}
      )
      @order_import.send_receipts = true
      @order_import.fail_on_error = true
      @order_import.upload_file.file = import_file
      @order_import.upload_file.save!
      @order_import.save!

      # expectations
      Notifier.expects(:order_receipt).once.returns( stub({:deliver => nil }) )

      # run the import
      @order_import.process!
    end
  end

  describe "import with two orders, first order has od with an error" do
    before :each do
      Order.destroy_all
      @import_file = generate_import_file(
        {:product_name => "Invalid Item Name"},
        {}, # valid order_detail, but same order key as above
        {:username => "guest2"} # diff user == diff order 
      )
      @order_import.upload_file.file = @import_file
      @order_import.upload_file.save!
      @order_import.send_receipts = true
      @order_import.save!
    end

    context "save nothing on error mode" do
      before :each do
        @order_import.fail_on_error = true
        @order_import.save!
      end

      it "shouldn't create any orders" do
        lambda {
          @order_import.process!
        }.should_not change(Order, :count).from(0).to(1) 
      end

      it "shouldn't send out any notifications" do
        Notifier.expects(:order_receipt).never
        @order_import.process!
      end

      it "should have all rows in its error report" do
        @order_import.process!
        import_file_rows = @import_file.read.split("\n").length
        error_file_rows = @order_import.error_file.file.to_file.read.split("\n").length
        
        error_file_rows.should == import_file_rows
      end
    end

    context "save clean orders mode" do
      before :each do
        @order_import.fail_on_error = false
        @order_import.save!
      end

      it "should create 1 order" do
        lambda {
          @order_import.process!
        }.should change(Order, :count).from(0).to(1) 

      end

      it "should send out notification for second order" do
        Notifier.expects(:order_receipt).once.returns( stub({:deliver => nil }) )
        @order_import.process!
      end

      it "should have first two rows in its error report" do
        @order_import.process!
        import_file_rows = @import_file.read.split("\n").length
        error_file_rows = @order_import.error_file.file.to_file.read.split("\n").length
        
        # minus one because one order (and order_detail) will have been created
        error_file_rows.should == import_file_rows - 1
      end
    end
  end
end
