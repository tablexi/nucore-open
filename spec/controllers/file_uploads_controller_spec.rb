require "rails_helper"
require "controller_spec_helper"

RSpec.describe FileUploadsController do
  render_views

  it "routes", :aggregate_failures do
    expect(get: "/#{facilities_route}/alpha/services/1/files/upload").to route_to(controller: "file_uploads", action: "upload", facility_id: "alpha", product: "services", product_id: "1")
    expect(post: "/#{facilities_route}/alpha/services/1/files").to route_to(controller: "file_uploads", action: "create", facility_id: "alpha", product: "services", product_id: "1")
  end

  before(:all) { create_users }

  before :each do
    @authable         = FactoryGirl.create(:facility)
    @facility_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @service          = @authable.services.create(FactoryGirl.attributes_for(:service, facility_account_id: @facility_account.id))
    assert @service.valid?
  end

  context "upload info" do

    before :each do
      @method = :get
      @action = :upload
      @params = {
        facility_id: @authable.url_name,
        product: "services",
        product_id: @service.url_name,
        file_type: "info",
      }
    end

    it_should_allow_operators_only do
      expect(response).to be_success
    end

  end

  context "create info" do

    before(:each) do
      @method = :post
      @action = :create
      @params = {
        facility_id: @authable.url_name,
        product: "services",
        product_id: @service.url_name,
        stored_file: {
          name: "File 1",
          file_type: "info",
          file: fixture_file_upload("#{Rails.root}/spec/files/template1.txt"),
        },
      }
    end

    it_should_allow_managers_and_senior_staff_only :redirect do
      expect(assigns[:product]).to eq(@service)
      expect(response).to redirect_to(upload_product_file_path(@authable, @service.parameterize, @service, file_type: "info"))
      expect(@service.reload.stored_files.size).to eq(1)
      expect(@service.reload.stored_files.collect(&:name)).to eq(["File 1"])
    end

    it "should render upload template when no file specified" do
      @params[:stored_file][:file] = ""
      sign_in @admin
      do_request
      is_expected.to render_template("upload")
    end

  end

  context "uploader_create" do

    before :each do
      @method = :post
      @action = :uploader_create
      create_order_detail
      @params = {
        facility_id: @authable.url_name,
        product: "services",
        product_id: @service.url_name,
        qqfile: fixture_file_upload("#{Rails.root}/spec/files/flash_file.swf", "application/x-shockwave-flash"),
        file_type: "info",
        order_detail_id: @order_detail.id,
      }
    end

    context "product info" do
      it_should_allow_managers_and_senior_staff_only
    end

    context "sample_result" do
      before :each do
        @params.merge!(file_type: "sample_result")
      end

      it_should_allow_all(facility_operators) do
        is_expected.to respond_with :success
      end

      describe "with a duplicate filename" do
        let!(:existing_file) { FactoryGirl.create(:stored_file, :results, order_detail: @order_detail, name: "flash_file.swf") }

        it "returns an error" do
          sign_in @admin
          do_request
          expect(response.body).to eq("Filename already exists for this order")
        end
      end
    end

  end

  context "product_survey" do

    before :each do
      @method = :get
      @action = :product_survey
      @params = { facility_id: @authable.url_name, product: @service.id, product_id: @service.url_name }
    end

    it_should_allow_managers_and_senior_staff_only do
      expect(assigns[:product]).to eq(@service)
      expect(assigns[:file]).to be_kind_of StoredFile
      expect(assigns[:file]).to be_new_record
      expect(assigns[:survey]).to be_kind_of ExternalService
      expect(assigns[:survey]).to be_new_record
    end

  end

  context "create_product_survey" do

    before :each do
      @method = :post
      @action = :create_product_survey
      @survey_param = ExternalServiceManager.survey_service.name.underscore.to_sym
      @ext_service_location = "http://remote.surveysystem.com/surveys"
      @params = {
        :facility_id => @authable.url_name,
        :product => @service.id,
        :product_id => @service.url_name,
        @survey_param => {
          location: @ext_service_location,
        },
      }
    end

    it "should do nothing if location not given" do
      @params[@survey_param] = nil
      maybe_grant_always_sign_in :director
      do_request
      expect(assigns[:product]).to eq(@service)
      expect(assigns[:survey]).to be_kind_of ExternalService
      expect(assigns[:survey]).to be_new_record
      expect(assigns[:survey].errors[:base]).not_to be_empty
    end

    it_should_allow_managers_and_senior_staff_only :redirect do
      expect(assigns[:product]).to eq(@service)
      expect(@service.reload.external_services.size).to eq(1)
      expect(@service.external_services[0].location).to eq(@ext_service_location)
      is_expected.to set_flash
      assert_redirected_to product_survey_path(@authable, @service.parameterize, @service)
    end

  end

  context "destroy" do

    before :each do
      @method = :delete
      @action = :destroy

      create_order_detail
      @file_upload = FactoryGirl.create(:stored_file,
                                        order_detail_id: @order_detail.id,
                                        created_by: @admin.id,
                                        product: @service,
                                       )

      @params = {
        facility_id: @authable.url_name,
        product: "services",
        product_id: @service.url_name,
        id: @file_upload.id,
      }
    end

    context "info" do
      it_should_allow_managers_and_senior_staff_only :redirect
    end

    context "sample_result" do
      before :each do
        @sample_result = FactoryGirl.create(:stored_file,
                                            order_detail_id: @order_detail.id,
                                            created_by: @staff.id,
                                            product: @service,
                                            file_type: "sample_result",
                                           )
        @params.merge!(id: @sample_result.id)
      end

      it_should_allow_all(facility_operators) do
        is_expected.to respond_with :redirect
      end

    end
  end

  def create_order_detail
    @facility_account = FactoryGirl.create(:facility_account, facility: @authable)
    @product = FactoryGirl.create(:item,
                                  facility_account: @facility_account,
                                  facility: @authable,
                                 )
    @account = create_nufs_account_with_owner
    @order = FactoryGirl.create(:order,
                                facility: @authable,
                                user: @director,
                                created_by: @director.id,
                                account: @account,
                                ordered_at: Time.zone.now,
                               )
    @price_group = FactoryGirl.create(:price_group, facility: @authable)
    @price_policy = FactoryGirl.create(:item_price_policy, product: @product, price_group: @price_group)
    @order_detail = FactoryGirl.create(:order_detail, order: @order, product: @product, price_policy: @price_policy)
  end
end
