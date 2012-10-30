class FacilityAccountsController < ApplicationController
  module Overridable
    extend ActiveSupport::Concern

    module ClassMethods
      def billing_access_checked_actions
        [ :accounts_receivable, :show_statement ]
      end
    end

    module InstanceMethods
      def account_class_params
        params[:account] || params[:nufs_account]
      end

      def configure_new_account(account)
        # set temporary expiration to be updated later
        account.valid? # populate virtual charstring attributes required by set_expires_at
        account.errors.clear

        # be verbose with failures. Too many tasks (#29563, #31873) need it
        begin
          account.set_expires_at!
          account.errors.add(:base, I18n.t('controllers.facility_accounts.create.expires_at_missing')) unless account.expires_at
        rescue ValidatorError => e
          account.errors.add(:base, e.message)
        end
      end
    end
  end

  include Overridable

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => Account
  before_filter :check_billing_access, :only => billing_access_checked_actions

  layout 'two_column'

  def initialize
    @active_tab = 'admin_billing'
    super
  end

  # GET /facilties/:facility_id/accounts
  def index
    @accounts = Account.has_orders_for_facility(current_facility).paginate(:page => params[:page])
  end

  # GET /facilties/:facility_id/accounts/:id
  def show
    @account = Account.find(params[:id])
  end

  # GET /facilities/:facility_id/accounts/new
  def new
    @owner_user = User.find(params[:owner_user_id])
    @account    = @owner_user.accounts.new(:expires_at => Time.zone.now + 1.year)
  end

  # GET /facilities/:facility_id/accounts/:id/edit
  def edit
    @account = Account.find(params[:id])
  end

  # PUT /facilities/:facility_id/accounts/:id
  def update
    @account     = Account.find(params[:id])
    class_params = account_class_params

    if @account.is_a?(AffiliateAccount)
      class_params[:affiliate]=Affiliate.find_by_name(class_params[:affiliate])
      class_params[:affiliate_other]=nil if class_params[:affiliate] != Affiliate::OTHER
    end

    if @account.update_attributes(class_params)
      flash[:notice] = I18n.t('controllers.facility_accounts.update')
      redirect_to facility_account_path
    else
      render :action => "edit"
    end
  end

  # POST /facilities/:facility_id/accounts
  def create
    class_params        = account_class_params
    acct_class=Class.const_get(params[:class_type])

    if acct_class.included_modules.include?(AffiliateAccount)
      class_params[:affiliate]=Affiliate.find_by_name(class_params[:affiliate])
      class_params[:affiliate_other]=nil if class_params[:affiliate] != Affiliate::OTHER
    end

    @owner_user         = User.find(params[:owner_user_id])
    @account            = acct_class.new(class_params)
    @account.created_by = session_user.id
    @account.account_users_attributes = [{:user_id => params[:owner_user_id], :user_role => 'Owner', :created_by => session_user.id }]
    @account.facility_id = current_facility.id if @account.class.limited_to_single_facility?

    configure_new_account @account
    return render :action => 'new' unless @account.errors[:base].empty?

    if @account.save
      flash[:notice] = 'Account was successfully created.'
      redirect_to(user_accounts_path(current_facility, @account.owner_user)) and return
    else
      render :action => 'new'
    end
  end

  def new_account_user_search
  end

  def user_search
  end

  # GET /facilities/:facility_id/accounts/search
  def search
    flash.now[:notice] = 'This page is not yet implemented'
  end

  # GET/POST /facilities/:facility_id/accounts/search_results
  def search_results
    owner_where_clause =<<-end_of_where
      (
        LOWER(users.first_name) LIKE :term
        OR LOWER(users.last_name) LIKE :term
        OR LOWER(users.username) LIKE :term
        OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
      )
      AND account_users.user_role = :acceptable_role
      AND account_users.deleted_at IS NULL
    end_of_where
    term   = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length >= 3

      # retrieve accounts matched on user for this facility
      @accounts = Account.joins(:account_users => :user).for_facility(current_facility).where(
        owner_where_clause,
        :term             => term,
        :acceptable_role  => 'Owner').
        order('users.last_name, users.first_name')
      
      # retrieve accounts matched on account_number for this facility
      @accounts += Account.for_facility(current_facility).where(
        "LOWER(account_number) LIKE ?", term).
        order('type, account_number')
      
      # only show an account once.
      @accounts = @accounts.uniq.paginate(:page => params[:page]) #hash options and defaults - :page (1), :per_page (30), :total_entries (arr.length)
    else
      flash.now[:errors] = 'Search terms must be 3 or more characters.'
    end
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def user_accounts
    @user = User.find(params[:user_id])
  end


  # GET /facilities/:facility_id/accounts/:account_id/members
  def members
    @account = Account.find(params[:account_id])
  end

  # GET /facilities/:facility_id/accounts_receivable
  def accounts_receivable
    @account_balances = {}
    order_details = OrderDetail.for_facility(current_facility).complete
    order_details.each do |od|
      @account_balances[od.account_id] = @account_balances[od.account_id].to_f + od.total.to_f
    end
    @accounts = Account.find(@account_balances.keys)
  end
  
  # GET /facilities/:facility_id/accounts/:account_id/statements/:statement_id
  def show_statement
    @account = Account.find(params[:account_id])
    @facility = current_facility
    action='show_statement'

    case params[:statement_id]
      when 'list'
        action += '_list'
        @statements = Statement.where(:facility_id => current_facility.id, :account_id => @account).order('created_at DESC').all.paginate(:page => params[:page])
      when 'recent'
        @order_details = @account.order_details.for_facility(@facility).delete_if{|od| od.order.state != 'purchased'}
        @order_details = @order_details.paginate(:page => params[:page])
      else
        @statement=Statement.find(params[:statement_id].to_i)
    end

    respond_to do |format|
      format.html { render :action => action }
      format.pdf  { render :template => '/statements/show.pdf.prawn' }
    end
  end
  
  # GET /facilities/:facility_id/accounts/:account_id/suspend
  def suspend
    @account = Account.find(params[:account_id])

    begin
      @account.suspend!
      flash[:notice] = I18n.t 'controllers.facility_accounts.suspend.success'
    rescue => e
      flash[:notice] = e.message || I18n.t('controllers.facility_accounts.suspend.failure')
    end

    redirect_to facility_account_path(current_facility, @account)
  end

  # GET /facilities/:facility_id/accounts/:account_id/unsuspend
  def unsuspend
    @account = Account.find(params[:account_id])

    begin
      @account.unsuspend!
      flash[:notice] = I18n.t 'controllers.facility_accounts.unsuspend.success'
    rescue => e
      flash[:notice] = e.message || I18n.t('controllers.facility_accounts.unsuspend.failure')
    end

    redirect_to facility_account_path(current_facility, @account)
  end

end
