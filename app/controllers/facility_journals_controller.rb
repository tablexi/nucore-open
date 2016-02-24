class FacilityJournalsController < ApplicationController

  include NUCore::Database::ArrayHelper
  include DateHelper
  include CSVHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :check_billing_access
  before_filter :init_journals, except: :create_with_search
  helper_method :has_pending_journals?

  include TransactionSearch

  layout "two_column"

  def initialize
    @subnav     = "billing_nav"
    @active_tab = "admin_billing"
    super
  end

  # GET /facilities/journals
  def index
    set_pending_journals
  end

  # GET /facilities/journals/new
  def new_with_search
    set_default_variables
    @layout = "two_column_head"
  end

  # PUT /facilities/journals/:id
  def update
    @pending_journal = @journal

    action = Journals::Closer.new(@pending_journal, params[:journal].merge(updated_by: session_user.id))

    if action.perform params[:journal_status]
      flash[:notice] = I18n.t "controllers.facility_journals.update.notice"
      redirect_to facility_journals_path(current_facility)
    else
      @order_details = OrderDetail.for_facility(current_facility).need_journal
      set_earliest_journal_date
      set_pending_journals

      # move error messages for pending journal into the flash
      if @pending_journal.errors.any?
        flash[:error] = @journal.errors.full_messages.join("<br/>").html_safe
      end

      @earliest_journal_date = params[:journal_date] || @earliest_journal_date
      render action: :index
    end
  end

  # POST /facilities/journals
  def create_with_search
    new_journal_from_params
    verify_journal_date_format

    # The referer can have a crazy long query string depending on how many checkboxes
    # are selected. We've seen Apache not like stuff like that and give a "malformed
    # header from script. Bad header" error which causes the page to completely bomb out.
    # (See Task #48311). This is just preventative.
    referer = response.headers["Referer"]
    response.headers["Referer"] = referer[0..referrer.index("?")] if referer.present?

    if @journal.errors.blank? && @journal.save
      @journal.create_spreadsheet if Settings.financial.journal_format.xls
      flash[:notice] = I18n.t("controllers.facility_journals.create.notice")
      redirect_to facility_journals_path(current_facility)
    else
      flash_error_messages
      remove_ugly_params
      redirect_to new_facility_journal_path
    end
  end

  # GET /facilities/journals/:id
  def show
    @journal_rows = @journal.journal_rows
    @filename = "journal_#{@journal.id}_#{@journal.created_at.strftime('%Y%m%d')}"

    respond_to do |format|
      format.xml do
        headers["Content-Disposition"] = "attachment; filename=\"#{@filename}.xml\""
      end

      format.csv do
        @show_uid = @journal_rows.joins(order_detail: { order: :user }).where("users.uid IS NOT NULL").any?
        set_csv_headers("#{@filename}.csv")
      end

      format.xls { redirect_to @journal.download_url }

      format.any { @order_details = @journal.order_details }
    end
  end

  def reconcile
    if params[:order_detail_ids].blank?
      flash[:error] = "No orders were selected to reconcile"
      redirect_to(facility_journal_path(current_facility, @journal)) && return
    end
    rec_status = OrderStatus.reconciled.first
    order_details = OrderDetail.for_facility(current_facility).where(id: params[:order_detail_ids]).readonly(false)
    order_details.each do |od|
      if od.journal_id != @journal.id
        flash[:error] = "Order detail #{od} does not belong to this journal! Please reconcile without it."
        redirect_to(facility_journal_path(current_facility, @journal)) && return
      end
      od.change_status!(rec_status)
    end
    flash[:notice] = "The selected orders have been reconciled successfully"
    redirect_to(facility_journal_path(current_facility, @journal)) && return
  end

  private

  def new_journal_from_params
    @journal = Journal.new(
      created_by: session_user.id,
      journal_date: parse_usa_date(params[:journal_date]),
      order_details_for_creation: order_details_for_creation,
    )
  end

  def verify_journal_date_format
    if params[:journal_date].present? && !usa_formatted_date?(params[:journal_date])
      @journal.errors.add(:journal_date, :blank)
    end
  end

  def order_details_for_creation
    return [] unless params[:order_detail_ids].present?
    array_slice(params[:order_detail_ids]).inject([]) do |order_details, order_detail_ids|
      order_details.concat(@order_details.includes(:order).where(id: order_detail_ids).to_a)
    end
  end

  def set_pending_journals
    @pending_journals = @journals.where(is_successful: nil)
  end

  def set_earliest_journal_date
    @earliest_journal_date = [
      @order_details.collect(&:fulfilled_at).max,
      JournalCutoffDate.first_valid_date,
    ].compact.max
  end

  def set_default_variables
    @order_details = @order_details.need_journal

    set_pending_journals
    set_earliest_journal_date

    blocked_facility_ids = Journal.facility_ids_with_pending_journals
    if cross_facility? || !has_pending_journals?
      @order_detail_action = :create
      @action_date_field = { journal_date: @earliest_journal_date }
    end
  end

  def init_journals
    @journals = Journal.for_facilities(manageable_facilities, manageable_facilities.size > 1).includes(:journal_rows).order("journals.created_at DESC")
    jid = params[:id] || params[:journal_id]
    @journal = @journals.find(jid) if jid
    @journals = @journals.paginate(page: params[:page], per_page: 10)
  end

  def has_pending_journals?
    current_facility.has_pending_journals?
  end

  def flash_error_messages
    msg = ""

    @journal.errors.full_messages.each do |error|
      msg += "#{error}<br/>"

      if msg.size > 2000 # don't overflow session (flash) cookie
        msg += I18n.t "controllers.facility_journals.create_with_search.more_errors"
        break
      end
    end

    flash[:error] = msg.html_safe if msg.present?
  end

end
