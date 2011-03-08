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
    @statements = current_facility.statements.find(:all)
    flash.now[:notice] = 'No statements have been sent' if @statements.empty?
  end

  # GET /facilities/:facility_id/statements/pending
  def pending
    @accounts = Account.need_statements(current_facility)
    flash.now[:notice] = 'No accounts currently require statement notification' if @accounts.empty?
  end

  # POST /facilities/:facility_id/statements/email
  def email
    unless params[:account_ids]
      flash[:error] = 'No accounts selected'
      redirect_to pending_facility_statements_path and return
    end
    accounts = Account.find(params[:account_ids])

    begin
      statement = Statement.create!({:facility => current_facility, :invoice_date => Time.zone.now + 7.days, :created_by => session_user.id})
    rescue Exception => e
      flash[:error] = "An error was encountered while sending emails"
      redirect_to pending_facility_statements_path and return
    end

    error = false
    accounts.each do |a|
      a.transaction do
        begin
          a.notify_users.each {|u| Notifier.deliver_statement(:user => u, :facility => current_facility, :account => a, :statement => statement)}
          raise ActiveRecord::Rollback unless a.update_account_transactions_with_statement(statement)
        rescue Exception => e
          flash[:error] = "An error was encountered while sending some statement emails"
          error = true
          raise ActiveRecord::Rollback
        end
      end
      if error
        redirect_to pending_facility_statements_path and return
      end
    end
    flash[:notice] = 'Statements sent successfully'
    redirect_to pending_facility_statements_path
  end

  # GET /facilities/:facility_id/statements/accounts_receivable
  def accounts_receivable
    @account_balances = {}
    if params[:show_all]
      AccountTransaction.find(:all, :group => 'account_id', :select => 'account_id, SUM(transaction_amount) AS balance', :conditions => ['facility_id = ? AND finalized_at <= ?', current_facility.id, Time.zone.now]).each do |at|
        @account_balances[at.account_id] = at.balance
      end
    else
      AccountTransaction.find(:all, :conditions => ['facility_id = ?', current_facility.id], :group => 'account_id', :select => 'account_id, SUM(transaction_amount) AS balance',  :conditions => ['facility_id = ? AND finalized_at <= ?', current_facility.id, Time.zone.now], :having => 'SUM(transaction_amount) > 0').each do |at|
        @account_balances[at.account_id] = at.balance
      end
    end
    # TODO add pagination here
    @accounts = Account.find(@account_balances.keys)
  end

  # GET /facilities/:facility_id/statements/:id
  def show
    @statement = Statement.find(params[:id])
  end
end
