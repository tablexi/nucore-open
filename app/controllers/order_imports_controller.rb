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
        # ensure created_by is in place before upload file creation
        @order_import=OrderImport.new
        @order_import.created_by=session_user.id
        @order_import.upload_file=params[:order_import].delete(:upload_file)
        @order_import.attributes=params[:order_import]
        @order_import.save!

        result=@order_import.process!
      end

      if result.blank?
        flash.now[:notice]=I18n.t 'controllers.order_imports.create.blank'
      elsif result.failed?
        flash.now[:error]=I18n.t 'controllers.order_imports.create.failure', :successes=> result.successes, :failures => result.failures
      else
        flash.now[:notice]=I18n.t 'controllers.order_imports.create.success', :successes=> result.successes
      end
    rescue => e
      Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
      flash.now[:error]=I18n.t 'controllers.order_imports.create.error', :error => e.message
    end

    render :action => 'show'
  end

end
