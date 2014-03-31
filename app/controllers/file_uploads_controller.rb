class FileUploadsController < ApplicationController
  admin_tab           :all
  before_filter       :authenticate_user!
  before_filter       :check_acting_as
  before_filter       :init_current_facility
  skip_before_filter  :verify_authenticity_token, :only => :create

  load_and_authorize_resource :class => StoredFile, :except => :uploader_create

  layout 'two_column'

  def initialize
    @active_tab = 'admin_products'
    super
  end

  # GET /facilities/1/services/3/files/upload?type=info
  # GET /facilities/1/services/3/files/upload?type=template
  # GET /facilities/1/services/3/files/upload?type=template_result
  def upload
    @klass   = params[:product]
    @product = current_facility.send(@klass).find_by_url_name!(params[:product_id])
    @file    = @product.stored_files.new(:file_type => params[:file_type])
  end

  # POST /facilities/1/services/3/files
  def create
    @klass   = params[:product]
    @product = current_facility.send(@klass).find_by_url_name!(params[:product_id])

    @file = @product.stored_files.new(params[:stored_file].merge(:created_by => session_user.id))

    if @file.save
      flash[:notice] = "File uploaded"
      redirect_to(upload_product_file_path(current_facility, @product.parameterize, @product, :file_type => @file.file_type)) and return
    end
    render :upload
  end

  # POST /facilities/:facility_id/:product/:product_id/uploader_files
  def uploader_create
    @klass    = params[:product]
    @product  = current_facility.send(@klass).find_by_url_name!(params[:product_id])

    @options = Hash[:swf_uploaded_data => params[:fileData], :name => params[:Filename],
                    :file_type => params[:file_type], :order_detail_id => params[:order_detail_id],
                    :created_by => session_user.id]
    @upload = @product.stored_files.new(@options)
    authorize! :uploader_create, @upload
    @upload.save!

    render :text => @upload.file.url
  end

  # GET /facilities/1/services/3/files/survey_upload
  def product_survey
    @product  = current_facility.services.find_by_url_name!(params[:product_id])
    @file     = @product.stored_files.new(:file_type => 'template')
    @survey = ExternalServiceManager.survey_service.new
  end

  def create_product_survey
    @product = current_facility.services.find_by_url_name!(params[:product_id])

    if params[:stored_file]
      create_product_survey_from_file
    else
      create_product_survey_from_url
    end
    render :product_survey unless performed?
  end

  def destroy
    @klass   = params[:product]
    @product = current_facility.send(@klass).find_by_url_name!(params[:product_id])
    @file    = @product.stored_files.find(params[:id])

    if @product.stored_files.destroy(@file)
      flash[:notice] = 'The file was deleted successfully'
    else
      flash[:error] = 'An error was encountered while attempting to delete the file'
    end

    # use return_to if it was sent
    @return_to = params[:return_to]
    if @file.file_type == 'template'
      redirect_to(@return_to || product_survey_path(current_facility, @product.parameterize, @product)) and return
    else
      redirect_to(@return_to || upload_product_file_path(current_facility, @product.parameterize, @product, :file_type => @file.file_type)) and return
    end
  end

  protected

  def manage_path(facility, product)
    eval("manage_facility_#{@klass.singularize}_path(current_facility, @product)")
  end

  private

  def create_product_survey_from_file
    @file = @product.stored_files.new(params[:stored_file].merge(:created_by => session_user.id, :name => 'Order Form Template'))
    @file.transaction do
      begin
        unless @product.stored_files.template.all? {|t| t.destroy}
          raise ActiveRecord::Rollback
        end
        @file.save!
        flash[:notice] = "Order File Template uploaded"
        redirect_to(product_survey_path(current_facility, @product.parameterize, @product)) and return
      rescue => e
        @file.errors.add(:base, "Order File Template delete error: #{e.message}")
        raise ActiveRecord::Rollback
      end
    end
    @survey = ExternalServiceManager.survey_service.new
  end

  def create_product_survey_from_url
    survey_param=ExternalServiceManager.survey_service.name.underscore.to_sym

    if params[survey_param].nil? || params[survey_param][:location].blank?
      @survey = ExternalServiceManager.survey_service.new
      @survey.errors.add(:base, "No location specified")
    else
      begin
        url = params[survey_param][:location]
        ext=ExternalServiceManager.survey_service.find_or_create_by_location(:location => url)
        esp=ExternalServicePasser.where(passer_id: @product.id, external_service_id: ext.id).first

        if esp
          flash[:notice] = "That Online Order Form already exists"
        else
          flash[:notice] = "Online Order Form added"
          ExternalServicePasser.create!(:passer => @product, :external_service => ext)
        end

        redirect_to(product_survey_path(current_facility, @product.parameterize, @product)) and return
      rescue => e
        @survey ||= ExternalServiceManager.survey_service.new
        @survey.errors.add(:base, "Online Order Form add error: #{e.message}")
      end
    end
    @file = @product.stored_files.new(:file_type => 'template')
  end

end
