class FacilityJournalsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Journal

  layout 'two_column'
  
  def initialize
    @subnav     = 'billing_nav'
    @active_tab = 'admin_invoices'
    super
  end
  
  # GET /facilities/:facility_id/journals
  def index
    @pending_journal = Journal.find_by_facility_id_and_is_successful(current_facility.id, nil)
    @order_details   = OrderDetail.need_journal(current_facility)
    @journal         = current_facility.journals.new()
  end

  #PUT /facilities/:facility_id/journals/:id
  def update
    @pending_journal = Journal.find(params[:id])
    @pending_journal.updated_by = session_user.id

    Journal.transaction do
      begin
        # blank input
        @pending_journal.errors.add_to_base("Please select a journal status") if params[:journal_status].blank?

        # failed
        if params[:journal_status] == 'failed'
          @pending_journal.is_successful = false
          @pending_journal.update_attributes!(params[:journal])
          OrderDetail.update_all('journal_id = NULL', "journal_id = #{@pending_journal.id}") # null out journal_id for all order_details

        # succeeded, with errors
        elsif params[:journal_status] == 'succeeded_errors'
          @pending_journal.is_successful = true
          @pending_journal.update_attributes!(params[:journal])

        # if succeeded, no errors
        elsif params[:journal_status]
          @pending_journal.is_successful = true
          @pending_journal.update_attributes!(params[:journal])
          reconciled_status = OrderStatus.reconciled.first
          @pending_journal.order_details.each do |od|
            raise Exception unless od.change_status!(reconciled_status)
          end
        else
          raise Exception
        end

        flash[:notice] = "The journal file has been closed"
        redirect_to facility_journals_path and return
      rescue Exception => e
        @pending_journal.errors.add_to_base("An error was encountered while trying to close the journal")
        raise ActiveRecord::Rollback
      end
    end
    @order_details = OrderDetail.need_journal(current_facility)
    render :action => :index
  end

  # POST /facilities/:facility_id/journals
  def create
    @journal = current_facility.journals.new()
    @journal.created_by = session_user.id

    @update_order_details = OrderDetail.find(params[:order_detail_ids] || [])
    if @update_order_details.empty?
      @journal.errors.add_to_base("No orders were selected to journal")
    else
      if Journal.order_details_span_fiscal_years?(@update_order_details)
        flash[:error] = 'Journals may not span multiple fiscal years. Please select only orders in the same fiscal year.'
        redirect_to facility_journals_path and return
      else
        Journal.transaction do
          begin
            @journal.journal_date = @update_order_details.collect{ |od| od.fulfilled_at }.max
            @journal.save!
            @journal.create_journal_rows!(@update_order_details)
            OrderDetail.update_all(['journal_id = ?', @journal.id], ['id IN (?)', @update_order_details.collect{|od| od.id}])
            # create the spreadsheet
            @journal.create_spreadsheet
            flash[:notice] = "The journal file has been created successfully"
            redirect_to facility_journals_path and return
          rescue Exception => e
            @journal.errors.add_to_base("An error was encountered while trying to create the journal #{e}")
            Rails.logger.error(e.backtrace.join("\n"))
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    @pending_journal = Journal.find_by_facility_id_and_is_successful(current_facility.id, nil)
    @accounts        = NufsAccount.find(:all).reject{|a| a.facility_balance(current_facility) <= 0}
    @order_details   = OrderDetail.need_journal(current_facility)
    render :action => :index
  end

  # GET /facilities/:facility_id/journals/:id
  def show
    @journal = current_facility.journals.find(params[:id])

    if request.format.xml?
      @journal_rows = @journal.journal_rows
      headers["Content-type"] = "text/xml"
      headers['Content-Disposition'] = "attachment; filename=\"journal_#{@journal.id}_#{@journal.created_at.strftime("%Y%m%d")}.xml\"" 

      render 'show.xml.haml', :layout => false and return
    end

    @order_details = current_facility.order_details.find(:all, :conditions => {:journal_id => @journal.id})
  end

  def history
    @journals = current_facility.journals.find(:all, :order => 'journals.created_at DESC').paginate(:page => params[:page])
  end

  def reconcile
    @journal = current_facility.journals.find(params[:journal_id])

    if params[:order_detail_ids].blank?
      flash[:error] = 'No orders were selected to reconcile'
      redirect_to facility_journal_url(current_facility, @journal) and return
    end
    rec_status = OrderStatus.reconciled.first
    order_details = OrderDetail.find(params[:order_detail_ids])
    order_details.each do |od|
      if od.journal_id != @journal.id
        flash[:error] = 'An error was encountered while reconcile orders'
        redirect_to facility_journal_url(current_facility, @journal) and return
      end
      od.change_status!(rec_status)
    end
    flash[:notice] = 'The select orders have been reconciled successfully'
    redirect_to facility_journal_url(current_facility, @journal) and return
  end
end
