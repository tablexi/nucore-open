require 'spec_helper'; require 'controller_spec_helper'

describe FileUploadsController do
  integrate_views

  it "should route" do
    params_from(:get, "/facilities/alpha/services/1/files/upload").should ==
      {:controller => 'file_uploads', :action => 'upload', :facility_id => 'alpha', :product => 'services', :product_id => '1'}
    params_from(:post, "/facilities/alpha/services/1/files").should ==
      {:controller => 'file_uploads', :action => 'create', :facility_id => 'alpha', :product => 'services', :product_id => '1'}
    params_from(:post, "/facilities/alpha/services/1/files/survey_upload").should == 
      {:controller => 'file_uploads', :action => 'survey_create', :facility_id => 'alpha', :product => 'services', :product_id => '1'}
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
      should render_template('upload.html.haml')
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
        :fileData => ActionController::TestUploadedFile.new("#{Rails.root}/spec/files/flash_file.swf", 'application/x-shockwave-flash'),
        :Filename => "#{Rails.root}/spec/files/flash_file.swf",
        :file_type => 'info',
        :order_detail_id => @order_detail.id
      }
    end

    it_should_allow_managers_only

  end


  context 'survey_upload' do

    before :each do
      @method=:get
      @action=:survey_upload
      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
      }
    end

    it_should_allow_managers_only

  end


  context 'survey_create' do

    before :each do
      @method=:post
      @action=:survey_create
      @params={
        :facility_id => @authable.url_name,
        :product => 'services',
        :product_id => @service.url_name,
        :survey => {}
      }
    end

    it_should_allow_managers_only do
      assigns[:product].should == @service
      assigns[:survey].should be_new_record
      assigns[:survey].errors.on_base.should_not be_nil
      should render_template :survey_upload
    end

    it "should not allow surveys with > 1 section" do
      @params[:survey][:upload]=File.new("#{Rails.root}/spec/files/kitchen_sink_survey.rb")
      sign_in @admin
      do_request
      assigns[:product].should == @service

      # This is a valid test, and it should work in Oracle. It doesn't work with MySQL.
      # I believe this is because tests against MySQL run in a transaction (not so w/ Oracle)
      # and Service#import_survey imports via a system call
      assert_equal 0, @service.reload.surveys.size if NUCore::Database.oracle?
    end

    it "should allow upload after a failed upload" do
      @params[:survey][:upload]=File.new("#{Rails.root}/spec/files/kitchen_sink_survey.rb")
      sign_in @admin
      do_request
      assigns[:product].should == @service
      # should not create survey
      assert_equal 0, @service.surveys.size
      # try again
      @params[:survey][:upload] = File.new("#{Rails.root}/spec/files/alpha_survey.rb")
      do_request
      assigns[:product].should == @service

      if NUCore::Database.oracle?
        # These are valid tests, and they should work in Oracle. They doesn't work with MySQL.
        # I believe this is because tests against MySQL run in a transaction (not so w/ Oracle)
        # and Service#import_survey imports via a system call
        assert assigns[:survey].valid?
        assert_equal 1, @service.surveys.size
      end
    end

    it 'should test :file_upload param'
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
    @account=Factory.create(:nufs_account)
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