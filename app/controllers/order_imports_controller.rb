class OrderImportsController < ApplicationController
  include ActionView::Helpers::TextHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  authorize_resource class: Order

  def initialize
    @active_tab = 'admin_orders'
    super
  end

  def new
    @order_import = OrderImport.new
  end

  def create
    begin
      process_order_import!
      flash_import_result
    rescue => e
      import_exception_alert(e)
    end

    render action: 'show'
  end

  private

  def flash_now(key, message)
    flash.now[key] = truncate(message, length: 2048)
  end

  def create_order_import!
    OrderImport.create!(
      params[:order_import].merge(
        created_by: session_user.id,
        upload_file: stored_file,
        facility: @current_facility
      )
    )
  end

  def flash_import_result
    case
    when @import_result.blank?
      flash_now(:notice, I18n.t('controllers.order_imports.create.blank'))
    when @import_result.failed?
      flash_now(:error, import_error_message)
    else
      flash_now(:notice, import_success_message)
    end
  end

  def fail_on_error?
    @order_import.try(:fail_on_error).present?
  end

  def failure_msg_key
    if fail_on_error?
      'controllers.order_imports.create.fail_immediately'
    else
      'controllers.order_imports.create.fail_continue_on_error'
    end
  end

  def import_error_message
    I18n.t failure_msg_key, @import_result.to_h
  end

  def import_exception_alert(exception)
    Rails.logger.error "#{exception.message}\n#{exception.backtrace.join("\n")}"
    flash_now(:error, import_exception_message(exception))
  end

  def import_exception_message(exception)
    I18n.t('controllers.order_imports.create.error', error: exception.message)
  end

  def import_success_message
    I18n.t 'controllers.order_imports.create.success', @import_result.to_h
  end

  def process_order_import!
    @import_result = if upload_file.present?
      @order_import = create_order_import!
      @order_import.process!
    end
  end

  def stored_file
    StoredFile.new(
      file: upload_file,
      file_type: 'import_upload',
      name: upload_file.try(:original_filename),
      created_by: session_user.id
    )
  end

  def upload_file
    @upload_file ||= params[:order_import].delete(:upload_file)
  end
end
