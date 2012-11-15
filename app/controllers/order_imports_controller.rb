class OrderImportsController < ApplicationController

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  authorize_resource :class => Order


  def initialize
    @active_tab = 'admin_orders'
    super
  end


  def new
    @order_import=OrderImport.new
  end


  def create
    begin
      result=nil
      OrderImport.transaction do
        file=params[:order_import].delete(:upload_file)
        stored_file=StoredFile.create!(
          :file => file,
          :file_type => 'import_upload',
          :name => file.original_filename,
          :created_by => session_user.id
        )

        @order_import=OrderImport.create!(
          params[:order_import].merge(
            :created_by => session_user.id,
            :upload_file => stored_file,
            :facility => @current_facility)
        )

        result=@order_import.process!
      end

      if result.blank?
        flash.now[:notice]=I18n.t 'controllers.order_imports.create.blank'
      elsif result.failed?
        if @order_import.fail_on_error
          failure_msg_key = 'controllers.order_imports.create.fail_immediately'
        else
          failure_msg_key = 'controllers.order_imports.create.fail_continue_on_error'
        end

        flash.now[:error]=I18n.t failure_msg_key, :successes => result.successes, :failures => result.failures
      else
        flash.now[:notice]=I18n.t 'controllers.order_imports.create.success', :successes => result.successes
      end
    rescue => e
      Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      flash.now[:error]=I18n.t 'controllers.order_imports.create.error', :error => e.message
    end

    render :action => 'show'
  end

end
