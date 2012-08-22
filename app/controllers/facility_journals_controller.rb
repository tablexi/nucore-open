class FacilityJournalsController < ApplicationController
  include DateHelper
  include CSVHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :check_billing_access
  before_filter :init_journals, :except => :create_with_search
  helper_method :has_pending_journals?

  include TransactionSearch
  
  layout 'two_column'
  
  def initialize
    @subnav     = 'billing_nav'
    @active_tab = 'admin_billing'
    super
  end
  
  # GET /facilities/journals
  def index
    set_pending_journals

    @journals = @journals.
      order('journals.created_at DESC').
      paginate(:page => params[:page])
  end

  # GET /facilities/journals/new
  def new_with_search
    set_default_variables
    @layout = "two_column_head"
  end
   
  #PUT /facilities/journals/:id
  def update
    @pending_journal = @journal
    @pending_journal.updated_by = session_user.id

    Journal.transaction do
      begin
        # blank input
        @pending_journal.errors.add(:base, I18n.t('controllers.facility_journals.update.error.status')) if params[:journal_status].blank?

        # failed
        if params[:journal_status] == 'failed'
          # Oracle is sometimes not leaving false as null
          @pending_journal.is_successful = NUCore::Database.boolean(false)
          @pending_journal.update_attributes!(params[:journal])
          OrderDetail.update_all('journal_id = NULL', "journal_id = #{@pending_journal.id}") # null out journal_id for all order_details

        # succeeded, with errors
        elsif params[:journal_status] == 'succeeded_errors'
          @pending_journal.is_successful = true
          @pending_journal.update_attributes!(params[:journal])

        # if succeeded, no errors
        elsif params[:journal_status] == 'succeeded'
          @pending_journal.is_successful = true
          @pending_journal.update_attributes!(params[:journal])
          reconciled_status = OrderStatus.reconciled.first
          @pending_journal.order_details.each do |od|
            raise Exception unless od.change_status!(reconciled_status)
          end
        else
          raise Exception
        end

        flash[:notice] = I18n.t 'controllers.facility_journals.update.notice'
        redirect_to facility_journals_url(current_facility) and return
      rescue Exception => e
        logger.error("ERROR: #{e.message}")
        @pending_journal.errors.add(:base, I18n.t('controllers.facility_journals.update.error.rescue'))
        raise ActiveRecord::Rollback
      end
    end
    @order_details = OrderDetail.for_facility(current_facility).need_journal
    set_soonest_journal_date
    set_pending_journals

    # move error messages for pending journal into the flash
    if @pending_journal.errors.any?
      flash[:error] = @journal.errors.full_messages.join("<br/>").html_safe
    end

    @soonest_journal_date = params[:journal_date] || @soonest_journal_date 
    render :action => :index
  end

  # POST /facilities/journals
  def create_with_search
    @journal = Journal.new
    @journal.created_by = session_user.id
    @journal.journal_date = parse_usa_date(params[:journal_date])
    
    if params[:order_detail_ids].present?
      @update_order_details = @order_details.includes(:order).where(:id => params[:order_detail_ids])
    else
      @update_order_details = []
    end

    # The referer can have a crazy long query string depending on how many checkboxes
    # are selected. We've seen Apache not like stuff like that and give a "malformed
    # header from script. Bad header" error which causes the page to completely bomb out.
    # (See Task #48311). This is just preventative.
    referer=response.headers['Referer']
    response.headers['Referer']=referer[0..referrer.index('?')] if referer.present?

    @update_order_details = OrderDetail.find(params[:order_detail_ids] || [])
    if @update_order_details.empty?
      @journal.errors.add(:base, I18n.t('controllers.facility_journals.create.errors.no_orders'))
    else
      if Journal.order_details_span_fiscal_years?(@update_order_details)
        @journal.errors.add(:base, I18n.t('controllers.facility_journals.create.errors.fiscal_span'))
      else
        # detect if this should be a multi-facility journal, set facility_id appropriately
        if @update_order_details.collect{|od|od.order.facility_id}.uniq.size > 1
          @journal.facility_id = nil
        else
          @journal.facility_id = @update_order_details.first.order.facility_id
        end
        Journal.transaction do
          begin
            @journal.save!

            # try to create the journal rows.
            # TK: if any journal_row creation/validation errors occur,
            # create_journal_rows blindly raises an exception
            row_errors = @journal.create_journal_rows!(@update_order_details)
            raise "<br/>"+row_errors.join('<br/>') if row_errors.present?

            # create the spreadsheet
            @journal.create_spreadsheet if Settings.financial.journal_format.xls
            flash[:notice] = I18n.t('controllers.facility_journals.create.notice')
            redirect_to facility_journals_url(current_facility) and return
          rescue Exception => e
            @journal.errors.add(:base, I18n.t('controllers.facility_journals.create.errors.rescue', :message => e.message))
            Rails.logger.error(e.backtrace.join("\n"))
            raise ActiveRecord::Rollback
          end
        end
      end
    end
    if @journal.errors.any?
      flash[:error] = @journal.errors.values.join("<br/>").html_safe
      remove_ugly_params
      redirect_to new_facility_journal_path and return
    end
    @layout = "two_column_head"
  end

  # GET /facilities/journals/:id
  def show
    @journal_rows = @journal.journal_rows
    @filename = "journal_#{@journal.id}_#{@journal.created_at.strftime("%Y%m%d")}"

    respond_to do |format|
      format.xml do
        headers['Content-Disposition'] = "attachment; filename=\"@filename.xml\""
        render :partial => 'rake_show', :locals => { :journal => @journal, :journal_rows => @journal_rows }, :layout => false
      end

      format.csv do
        @show_uid = @journal_rows.joins(:order_detail => {:order => :user}).where('users.uid IS NOT NULL').any?
        set_csv_headers("#{@filename}.csv")
      end

      format.any { @order_details = @journal.order_details }
    end
  end

  def reconcile
    if params[:order_detail_ids].blank?
      flash[:error] = 'No orders were selected to reconcile'
      redirect_to facility_journal_url(current_facility, @journal) and return
    end
    rec_status = OrderStatus.reconciled.first
    order_details = OrderDetail.for_facility(current_facility).where(:id => params[:order_detail_ids]).readonly(false)
    order_details.each do |od|
      if od.journal_id != @journal.id
        flash[:error] = "Order detail #{od.to_s} does not belong to this journal! Please reconcile without it."
        redirect_to facility_journal_url(current_facility, @journal) and return
      end
      od.change_status!(rec_status)
    end
    flash[:notice] = 'The selected orders have been reconciled successfully'
    redirect_to facility_journal_url(current_facility, @journal) and return
  end


  private
  
  def set_pending_journals
    @pending_journals = @journals.where(:is_successful => nil)
  end
  
  def set_soonest_journal_date
    @soonest_journal_date=@order_details.collect{ |od| od.fulfilled_at }.max
    @soonest_journal_date=Time.zone.now unless @soonest_journal_date
  end
  
  def set_default_variables
    @order_details   = @order_details.need_journal

    set_pending_journals
    set_soonest_journal_date

    blocked_facility_ids = Journal.facility_ids_with_pending_journals
    if all_facility? or !has_pending_journals?
      @order_detail_action = :create
      @action_date_field = {:journal_date => @soonest_journal_date}
    end
  end

  def init_journals
    @journals = Journal.for_facilities(manageable_facilities, manageable_facilities.size > 1).order("journals.created_at DESC")
    jid=params[:id] || params[:journal_id]
    @journal = @journals.find(jid) if jid
  end

  def has_pending_journals?
    current_facility.has_pending_journals?
  end
end
