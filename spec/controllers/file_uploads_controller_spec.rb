require 'spec_helper'; require 'controller_spec_helper'

describe FileUploadsController do
  render_views

  it "should route" do
    { :get => "/facilities/alpha/services/1/files/upload" }.should route_to(:controller => 'file_uploads', :action => 'upload', :facility_id => 'alpha', :product => 'services', :product_id => '1')
    { :post => "/facilities/alpha/services/1/files" }.should route_to(:controller => 'file_uploads', :action => 'create', :facility_id => 'alpha', :product => 'services', :product_id => '1')
    # params_from(:post, "/facilities/alpha/services/1/yui_files").should == 
    #   {:controller => 'file_uploads', :action => 'yui_create', :facility_id => 'alpha', :product => 'services', :product_id => '1'}
  end

  before(:all) { create_users }

  before :each do
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @service          = @authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    assert @service.valid?
  end


  context 'upload' do

    before :each do
      @method=:get
      @action=:upload
      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
        :file_type => 'info'
      }
    end

    it_should_allow_managers_only

  end


  context "create" do

    before(:each) do
      @method=:post
      @action=:create
      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
        :file_upload => {
          :name => "File 1",
          :file_type => 'info',
          :file => File.new("#{Rails.root}/spec/files/alpha_survey.rb")
        }
      }
    end

    it_should_allow_managers_only :redirect do
      assigns[:product].should == @service
      response.should redirect_to(upload_product_file_path(@authable, @service.parameterize, @service, :file_type => 'info'))
      @service.reload.file_uploads.size.should == 1
      @service.reload.file_uploads.collect(&:name).should == ['File 1']
    end

    it "should render upload template when no file specified" do
      @params[:file_upload][:file]=''
      sign_in @admin
      do_request
      should render_template('upload')
    end

  end


  context 'uploader_create' do

    before :each do
      @method=:post
      @action=:uploader_create
      create_order_detail
      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
        :fileData => ActionDispatch::TestProcess.fixture_file_upload("#{Rails.root}/spec/files/flash_file.swf", 'application/x-shockwave-flash'),
        :Filename => "#{Rails.root}/spec/files/flash_file.swf",
        :file_type => 'info',
        :order_detail_id => @order_detail.id
      }
    end

    it_should_allow_managers_only

  end


  context 'product_survey' do

    before :each do
      @method=:get
      @action=:product_survey
      @params={ :facility_id => @authable.url_name, :product => @service.id, :product_id => @service.url_name }
    end

    it_should_allow_managers_only do
      assigns[:product].should == @service
      assigns[:file].should be_kind_of FileUpload
      assigns[:file].should be_new_record
      assigns[:survey].should be_kind_of ExternalService
      assigns[:survey].should be_new_record
    end

  end


  context 'create_product_survey' do

    before :each do
      @method=:post
      @action=:create_product_survey
      @survey_param=ExternalServiceManager.survey_service.name.downcase.to_sym
      @ext_service_location='http://remote.surveysystem.com/surveys'
      @params={
        :facility_id => @authable.url_name,
        :product => @service.id,
        :product_id => @service.url_name,
        @survey_param => {
          :location => @ext_service_location
        }
      }
    end

    it 'should do nothing if location not given' do
      @params[@survey_param]=nil
      maybe_grant_always_sign_in :director
      do_request
      assigns[:product].should == @service
      assigns[:survey].should be_kind_of ExternalService
      assigns[:survey].should be_new_record
      assigns[:survey].errors[:base].should_not be_empty
    end

    it_should_allow_managers_only :redirect do
      assigns[:product].should == @service
      @service.reload.external_services.size.should == 1
      @service.external_services[0].location.should == @ext_service_location
      should set_the_flash
      assert_redirected_to product_survey_path(@authable, @service.parameterize, @service)
    end

  end


  context 'destroy' do

    before :each do
      @method=:delete
      @action=:destroy

      create_order_detail
      @file_upload=Factory.create(:file_upload,
        :order_detail_id => @order_detail.id,
        :created_by => @admin.id,
        :product => @service
      )

      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
        :id => @file_upload.id
      }
    end

    it_should_allow_managers_only :redirect

  end


  def create_order_detail
    @facility_account=Factory.create(:facility_account, :facility => @authable)
    @product=Factory.create(:item,
      :facility_account => @facility_account,
      :facility => @authable
    )
    @account=create_nufs_account_with_owner
    @order=Factory.create(:order,
      :facility => @authable,
      :user => @director,
      :created_by => @director.id,
      :account => @account,
      :ordered_at => Time.zone.now
    )
    @price_group=Factory.create(:price_group, :facility => @authable)
    @price_policy=Factory.create(:item_price_policy, :item => @product, :price_group => @price_group)
    @order_detail=Factory.create(:order_detail, :order => @order, :product => @product, :price_policy => @price_policy)
  end
end