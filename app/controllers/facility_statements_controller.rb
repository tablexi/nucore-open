class FacilityStatementsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Statement

  layout 'two_column'

  def initialize
    @active_tab = 'admin_invoices'
    super
  end

  # GET /facilities/:facility_id/statements
  def index
    @statements = current_facility.statements.find(:all, :order => 'statements.created_at DESC').paginate(:page => params[:page])
  end

  # GET /facilities/:facility_id/statements/pending
  def pending
    @accounts = Account.for_facility(current_facility)
  end

  # POST /facilities/:facility_id/statements/email
  def email
    unless params[:account_ids]
      flash[:error] = 'No payment sources selected'
      redirect_to pending_facility_statements_path and return
    end
    accounts = Account.find(params[:account_ids])

    error = false
    accounts.each do |a|
      details = a.order_details.need_statement(current_facility)
      next if details.empty?
      a.transaction do
        begin
          statement = Statement.create!({:facility => current_facility, :account_id => a.id, :created_by => session_user.id})
          details.each do |od|
            StatementRow.create!({ :statement_id => statement.id, :amount => od.total, :order_detail_id => od.id })
            od.statement_id = statement.id
            od.save!
          end
          a.notify_users.each {|u| Notifier.statement(:user => u, :facility => current_facility, :account => a, :statement => statement).deliver }
        rescue Exception => e
          error = true
          raise ActiveRecord::Rollback
        end
      end
    end
    if error
      redirect_to pending_facility_statements_path and return
    end
    flash[:notice] = 'The statements were created successfully'
    redirect_to pending_facility_statements_path
  end

  # GET /facilities/:facility_id/statements/accounts_receivable
  def accounts_receivable
    @account_balances = {}
    order_details = current_facility.order_details.complete
    order_details.each do |od|
      @account_balances[od.account_id] = @account_balances[od.account_id].to_f + od.total.to_f
    end
    @accounts = Account.find(@account_balances.keys)
  end

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end
end
