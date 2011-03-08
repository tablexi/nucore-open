class StatementsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_account

  load_and_authorize_resource

  def initialize
    @active_tab = 'accounts'
    super
  end

  # GET /accounts/:account_id/statements
  def index
    facility_ids = @account.account_transactions.find(:all, :select => :facility_id, :group => :facility_id).collect {|at| at.facility_id}
    @facilities  = Facility.find(:all, facility_ids, :order => :name)
  end

  # GET /accounts/:account_id/facilities/:facility_id/statements/:id
  def show
    @active_tab = 'accounts'
    @facility   = Facility.find_by_url_name!(params[:facility_id])
    @statements = @account.statements.final_for_facility(@facility).uniq

    if params[:id].to_s.downcase == 'recent'
      @account_txns   = @account.account_transactions.facility_recent(@facility)
      @prev_statement = @statements.first
      @new_payments   = @account.facility_recent_payment_balance(@facility) # includes credits
      @new_purchases  = @account.facility_recent_purchase_balance(@facility)
    else
      @statement      = @account.statements.find(params[:id])
      @prev_statement = @account.statements.find(:first, :conditions => ['statements.created_at < ?', @statement.created_at], :order => 'statements.created_at DESC')
      @new_payments   = @account.statement_payment_balance(@statement) # includes credits
      @new_purchases  = @account.statement_purchase_balance(@statement)
      @account_txns   = @statement.account_transactions.finalized
    end
    @balance_prev = @prev_statement ? @prev_statement.account_balance_due(@account) : 0
    @balance_due  = @balance_prev + @new_purchases  + @new_payments # payments are negative in the DB already

    prawnto :prawn => {
                  :left_margin   => 50,
                  :right_margin  => 50,
                  :top_margin    => 50,
                  :bottom_margin => 75 }

  end

  protected

  def init_account
    @account = session_user.accounts.find(params[:account_id])
  end


  private

  def ability_resource
    return @account
  end

end