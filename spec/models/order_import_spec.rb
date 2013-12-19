require 'spec_helper'
require 'controller_spec_helper'

require 'stringio'
require 'csv_helper'

CSV_HEADERS = ["Netid / Email", "Chart String" , "Product Name" , "Quantity" , "Order Date" , "Fulfillment Date"]

def errors_for_import_with_row(opts={})
  row = CSVHelper::CSV::Row.new(CSV_HEADERS, [
    opts[:username]           || @guest.username,
    opts[:account_number]     || "111-2222222-33333333-01",
    opts[:product_name]       || "Example Item",
    opts[:quantity]           || 1,
    opts[:order_date]         || default_order_date.strftime("%m/%d/%Y"),
    opts[:fulfillment_date]   || default_fulfilled_date.strftime("%m/%d/%Y")
  ])

  errs = @order_import.errors_for(row)
end

describe OrderImport do
  let(:default_order_date) { 4.days.ago.to_date }
  let(:default_fulfilled_date) { 3.days.ago.to_date }
  let(:fiscal_year_beginning) { SettingsHelper::fiscal_year_beginning }

  before(:all) do
    create_users
  end

  before :each do
    Timecop.freeze(fiscal_year_beginning + 5.days)

    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create!(FactoryGirl.attributes_for(:facility_account))

    grant_role(@director, @authable)
    @item             = @authable.items.create!(FactoryGirl.attributes_for(:item,
      :facility_account_id => @facility_account.id,
      :name => "Example Item"
    ))
    @service          = @authable.services.create!(FactoryGirl.attributes_for(:service,
      :facility_account_id => @facility_account.id,
      :name => "Example Service"
    ))

    # price stuff
    @price_group      = @authable.price_groups.create!(FactoryGirl.attributes_for(:price_group))
    @pg_member        = FactoryGirl.create(:user_price_group_member, :user => @guest, :price_group => @price_group)
    @item_pp=@item.item_price_policies.create!(FactoryGirl.attributes_for(:item_price_policy,
      :price_group_id => @price_group.id,
      :start_date => fiscal_year_beginning

    ))
    @service_pp=@service.service_price_policies.create!(FactoryGirl.attributes_for(:service_price_policy,
      :price_group_id => @price_group.id,
      :start_date => fiscal_year_beginning
    ))

    @guest2 = FactoryGirl.create :user, :username => 'guest2'
    @pg_member        = FactoryGirl.create(:user_price_group_member, :user => @guest2, :price_group => @price_group)
    @account          = FactoryGirl.create(:nufs_account,
      :description => "dummy account",
      :account_number => '111-2222222-33333333-01',
      :account_users_attributes =>
        (account_users_attributes_hash(:user => @guest) +
         account_users_attributes_hash(:user => @guest2, :created_by => @guest, :user_role => AccountUser::ACCOUNT_PURCHASER))
    )


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

  after :each do
    Timecop.return
  end


  # validation testing
  it { should belong_to :creator }
  it { should belong_to :upload_file }
  it { should belong_to :error_file }
  it { should validate_presence_of :upload_file }
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

      context 'product' do
        it "should have error when product isn't found" do
          errors_for_import_with_row(:product_name => "not_a_product_name").first.should match /find product/
        end

        it 'should have error when the product is deactivated' do
          @item.update_attributes(:is_archived => true)
          errors_for_import_with_row(:product_name => @item.name).first.should match /find product/
        end

        it 'should not have an error when the product is hidden' do
          @item.update_attributes(:is_hidden => true)
          errors_for_import_with_row(:product_name => @item.name).should be_empty
        end
      end


      it "should have error when product is service and has active survey" do
        Service.any_instance.stub(:active_survey?).and_return(true)
        errors_for_import_with_row(:product_name => "Example Service").first.should match /requires survey/
      end

      it "should have error when product is service and has active template" do
        Service.any_instance.stub(:active_template?).and_return(true)
        errors_for_import_with_row(:product_name => "Example Service").first.should match /requires template/
      end

      it "should handle bad order_date" do
        errors_for_import_with_row(:order_date => "02/31/2012").first.should match /Order Date/
      end

      it "should handle bad fullfillment_date" do
        errors_for_import_with_row(:fulfillment_date => "02/31/2012").first.should match /Fulfillment Date/
      end
    end

    it "should find user by email in addition to username" do
      errors_for_import_with_row(:username => @guest.email).should be_empty
    end

    describe "created order" do
      before :each do
        # run the import of row
        errors_for_import_with_row.should == []

        @created_order = Order.last
      end

      it "should have ordered_at set appropriately" do
        @created_order.ordered_at.to_date.should == default_order_date
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

        it "should have right fulfilled_at" do
          @created_order.order_details.each do |od|
            od.fulfilled_at.to_date.should == default_fulfilled_date
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

  whole_csv = CSVHelper::CSV.generate :headers => true do |csv|
    csv << CSV_HEADERS
    args.each do |opts|
      row = CSVHelper::CSV::Row.new(CSV_HEADERS, [
        opts[:username]           || 'guest',
        opts[:account_number]     || "111-2222222-33333333-01",
        opts[:product_name]       || "Example Item",
        opts[:quantity]           || 1,
        opts[:order_date]         || default_order_date.strftime("%m/%d/%Y"),
        opts[:fullfillment_date]  || default_fulfilled_date.strftime("%m/%d/%Y")
      ])
      csv << row
    end
  end

  return StringIO.new whole_csv
end

  describe "high-level calls" do
    context "save clean orders mode" do

      before :each do
        @order_import.fail_on_error = false
      end

      it "should send notifications (save clean orders mode)" do
        import_file = generate_import_file(
          {:order_date => default_order_date}, # valid rows
          {:order_date => default_order_date},


          # diff order date (so will be diff order)
          {
            :order_date => default_order_date + 1.day,
            :product_name => "Invalid Item Name"
          }
        )
        @order_import.send_receipts = true
        @order_import.upload_file.file = import_file
        @order_import.upload_file.save!
        @order_import.save!

        # expectations
        Notifier.should_receive(:order_receipt).once.and_return( stub({:deliver => nil }) )

        # run the import
        @order_import.process!
      end
    end

    context "save nothing on error mode" do
      before :each do
        @order_import.fail_on_error = true
      end

      context "notifications enabled" do
        before :each do
          @order_import.send_receipts = true
        end

        it "should not send notifications if error occured" do
          import_file = generate_import_file(
            {},
            {:product_name => "Invalid Item Name"}
          )
          @order_import.send_receipts = true
          @order_import.upload_file.file = import_file
          @order_import.upload_file.save!
          @order_import.save!

          # expectations
          Notifier.should_receive(:order_receipt).never

          # run the import
          @order_import.process!
        end

        it "should send notifications if no errors occured" do
          import_file = generate_import_file(
            {}
          )
          @order_import.upload_file.file = import_file
          @order_import.upload_file.save!
          @order_import.save!

          # expectations
          Notifier.should_receive(:order_receipt).once.and_return( stub({:deliver => nil }) )

          # run the import
          @order_import.process!
        end
      end

      context "notifications disabled" do
        before :each do
          @order_import.send_receipts = false
        end

        it "should not send notifications if notifications disabled" do
          import_file = generate_import_file(
            {}
          )
          @order_import.upload_file.file = import_file
          @order_import.upload_file.save!
          @order_import.save!

          # expectations
          Notifier.should_receive(:order_receipt).never

          # run the import
          @order_import.process!
        end
      end
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

      @import_file.rewind # saving reads the file and we want to make sure we're at the beginning
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
        Notifier.should_receive(:order_receipt).never
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
        Notifier.should_receive(:order_receipt).once.and_return( stub({:deliver => nil }) )
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

  describe "import with two 1 order 2 ods, second od has an error" do
    before :each do
      Order.destroy_all
      @import_file = generate_import_file(
        {}, # valid order_detail
        {:product_name => "Invalid Item Name"} # same order as above
      )
      @order_import.upload_file.file = @import_file
      @order_import.upload_file.save!
      @import_file.rewind

      @order_import.send_receipts = true
      @order_import.save!
    end

    context "save clean orders mode" do
      before :each do
        @order_import.fail_on_error = false
        @order_import.send_receipts = true
        @order_import.save!
      end

      it "shouldn't create any orders" do
        lambda {
          @order_import.process!
        }.should_not change(Order, :count)
      end

      it "shouldn't send out any notifications" do
        Notifier.should_receive(:order_receipt).never
        @order_import.process!
      end

      it "error report should have all rows (since only one order)" do
        @order_import.process!
        import_file_rows = @import_file.read.split("\n").length
        error_file_contents = @order_import.error_file.file.to_file.read
        error_file_rows = error_file_contents.split("\n").length
        error_file_rows.should == import_file_rows
      end
    end

    context "save nothing on error mode" do
      before :each do
        @order_import.fail_on_error = true
        @order_import.send_receipts = true
        @order_import.save!
      end

      it "shouldn't create any orders" do
        lambda {
          @order_import.process!
        }.should_not change(Order, :count)
      end

      it "shouldn't send out any notifications" do
        Notifier.should_receive(:order_receipt).never
        @order_import.process!
      end

      it "error report should have all rows (since only one order)" do
        @order_import.process!
        import_file_rows = @import_file.read.split("\n").length
        error_file_rows = @order_import.error_file.file.to_file.read.split("\n").length
        error_file_rows.should == import_file_rows
      end
    end
  end
end
