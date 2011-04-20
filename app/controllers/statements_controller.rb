class StatementsController < ApplicationController
  customer_tab  :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_account
  before_filter :init_statement, :except => :index

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

    if params[:id].to_s.downcase == 'recent'
      @account_txns   = @account.account_transactions.facility_recent(@facility)
    else
      @account_txns   = @statement.account_transactions.finalized
    end

    prawnto :prawn => {
                  :left_margin   => 50,
                  :right_margin  => 50,
                  :top_margin    => 50,
                  :bottom_margin => 75 }
  end


  private

  def ability_resource
    return @account
  end


  def init_account
    @account = session_user.accounts.find(params[:account_id])
  end

  #
  # Override CanCan's find -- it won't properly search by 'recent'
  def init_statement
    @facility=Facility.find_by_url_name!(params[:facility_id])
    @statements=@account.statements.final_for_facility(@facility).uniq
    @statement=params[:id].to_s.downcase == 'recent' ? @statements.first : @account.statements.find(params[:id])
  end

end