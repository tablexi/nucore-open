require 'spec_helper'
require 'controller_spec_helper'


describe OrderImportsController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


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


    context 'with a blank file' do

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


    def upload_file(file_name)
      ActionDispatch::TestProcess.fixture_file_upload("#{Rails.root}/spec/files/order_imports/#{file_name}", 'text/csv')
    end
  end

end
