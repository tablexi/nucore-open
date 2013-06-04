require 'spec_helper'
require 'controller_spec_helper'

  # helpers
  def upload_file(file_name)
    ActionDispatch::TestProcess.fixture_file_upload("#{Rails.root}/spec/files/order_imports/#{file_name}", 'text/csv')
  end

  def get_real_order_count(import_id)
    ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM orders where order_import_id = #{import_id}")
  end

describe OrderImportsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  # contexts
  context 'starting an import' do

    before :each do
      @action=:new
      @method=:get
    end

    it_should_allow_operators_only do
      assigns(:order_import).should be_new_record
      should render_template 'new'
    end

  end


  context 'doing an import' do
    context 'with a blank file' do
      before :each do
        @action=:create
        @method=:post
        @params.merge!({
          :order_import => {
            :upload_file => upload_file('blank.csv'),
            :fail_on_error => false,
            :send_receipts => false
          }
        })
      end

      it_should_allow_operators_only do
        flash[:error].should be_blank
        flash[:notice].should be_present
        should render_template 'show'
      end

      it 'should create new OrderImport record' do
        maybe_grant_always_sign_in :director
        lambda { do_request }.should change(OrderImport, :count).from(0).to(1)
      end

      it 'should create new StoredFile record' do
        maybe_grant_always_sign_in :director
        lambda { do_request }.should change(StoredFile, :count).from(0).to(1)
      end
    end

    context "with an erroneous file" do
      before :each do
        # necessary to purchase them
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
          :price_group_id => @price_group.id
        ))
        @service_pp=@service.service_price_policies.create!(FactoryGirl.attributes_for(:service_price_policy,
          :price_group_id => @price_group.id
        ))

        @guest2 = FactoryGirl.create :user, :username => 'guest2'
        @pg_member        = FactoryGirl.create(:user_price_group_member, :user => @guest2, :price_group => @price_group)
        user_attrs = account_users_attributes_hash(:user => @guest) + account_users_attributes_hash(:user => @guest2, :created_by => @guest, :user_role => 'Purchaser')
        @account          = FactoryGirl.create(:nufs_account,
          :description => "dummy account",
          :account_number => '111-2222222-33333333-01',
          :account_users_attributes => user_attrs
        )
      end

      context "with erroroneous import file" do
        context "save nothing mode" do
          it 'should not create orders if first od fails' do
            maybe_grant_always_sign_in :director
            @action=:create
            @method=:post
            @params.merge!({
              :order_import => {
                :upload_file => upload_file('first_od_error.csv'),
                :fail_on_error => true,
                :send_receipts => true
              }
            })

            do_request
            import_id = assigns(:order_import).id

            get_real_order_count(import_id).should == 0
          end

          it 'should not create orders if second od fails' do
            maybe_grant_always_sign_in :director
            @action=:create
            @method=:post
            @params.merge!({
              :order_import => {
                :upload_file => upload_file('second_od_error.csv'),
                :fail_on_error => true,
                :send_receipts => true
              }
            })

            do_request
            import_id = assigns(:order_import).id

            get_real_order_count(import_id).should == 0
          end
        end

        context "save complete orders (default) mode " do
          it 'should not create orders if first od fails' do
            maybe_grant_always_sign_in :director
            @action=:create
            @method=:post
            @params.merge!({
              :order_import => {
                :upload_file => upload_file('first_od_error.csv'),
                :fail_on_error => false,
                :send_receipts => true
              }
            })

            do_request
            import_id = assigns(:order_import).id

            get_real_order_count(import_id).should == 0
          end

          it 'should not create orders if second od fails' do
            maybe_grant_always_sign_in :director
            @action=:create
            @method=:post
            @params.merge!({
              :order_import => {
                :upload_file => upload_file('second_od_error.csv'),
                :fail_on_error => false,
                :send_receipts => true
              }
            })

            do_request
            import_id = assigns(:order_import).id
            get_real_order_count(import_id).should == 0
          end
        end
      end
    end
  end
end
