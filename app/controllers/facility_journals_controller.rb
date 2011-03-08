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
    @accounts        = NufsAccount.find(:all).reject{|a| a.facility_balance(current_facility) <= 0}
    @journal         = current_facility.journals.new()
  end

  #PUT /facilities/:facility_id/journals/:id
  def update
    @pending_journal = Journal.find(params[:id])
    @pending_journal.updated_by = session_user.id

    Journal.transaction do
      begin
        @pending_journal.update_attributes!(params[:journal])
        @pending_journal.create_payment_transactions!(:created_by => session_user.id) if @pending_journal.is_successful?
        flash[:notice] = "The journal file has been successfully closed"
        redirect_to facility_journals_path and return
      rescue Exception => e
        @pending_journal.errors.add_to_base("An error was encountered while trying to close the journal")
        raise ActiveRecord::Rollback
      end
    end
    @accounts = NufsAccount.find(:all).reject{|a| a.facility_balance(current_facility) <= 0}
    render :action => :index
  end

  # POST /facilities/:facility_id/journals
  def create
    @journal = current_facility.journals.new()
    @journal.created_by = session_user.id

    @update_accounts = Account.find(params[:account_ids] || [])
    if @update_accounts.empty?
      @journal.errors.add_to_base("No accounts were selected to journal")
    else
      Journal.transaction do
        begin
          @journal.save!
          @journal.create_journal_rows_for_accounts!(@update_accounts)
          # create the spreadsheet
          @journal.create_spreadsheet
          flash[:notice] = "The journal file has been created successfully"
          redirect_to facility_journals_path
          return
        rescue Exception => e
          @journal.errors.add_to_base("An error was encountered while trying to create the journal #{e}")
          raise ActiveRecord::Rollback
        end
      end
    end

    @pending_journal = Journal.find_by_facility_id_and_is_successful(current_facility.id, nil)
    @accounts        = NufsAccount.find(:all).reject{|a| a.facility_balance(current_facility) <= 0}
    render :action => :index
  end

  # GET /facilities/:facility_id/journals/:id
  def show
    @journal      = current_facility.journals.find(params[:id])
    @journal_rows = @journal.journal_rows

    headers["Content-type"] = "text/xml"
    headers['Content-Disposition'] = "attachment; filename=\"journal_#{@journal.id}_#{@journal.created_at.strftime("%Y%m%d")}.xml\"" 

    render 'show.xml.haml', :layout => false
  end
end
