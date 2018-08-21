# frozen_string_literal: true

class FacilityAccountsController < ApplicationController

  include AccountSuspendActions
  include SearchHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_account
  before_action :build_account, only: [:new, :create]

  authorize_resource :account

  before_action :check_billing_access, only: [:accounts_receivable]

  layout "two_column"

  def initialize
    @active_tab =
      if SettingsHelper.feature_on?(:manage_payment_sources_with_users)
        "admin_users"
      else
        "admin_billing"
      end
    super
  end

  # GET /facilties/:facility_id/accounts
  def index
    accounts = Account.with_orders_for_facility(current_facility)
    accounts = accounts.where(facility_id: nil) if current_facility.cross_facility?

    @accounts = accounts.paginate(page: params[:page])
  end

  # GET /facilties/:facility_id/accounts/:id
  def show
  end

  # GET /facilities/:facility_id/accounts/new
  def new
  end

  # POST /facilities/:facility_id/accounts
  def create
    # The builder might add some errors to base. If those exist,
    # we don't want to try saving as that would clear the original errors
    if @account.errors[:base].empty? && @account.save
      LogEvent.log(@account, :create, current_user)
      flash[:notice] = I18n.t("controllers.facility_accounts.create.success")
      redirect_to facility_user_accounts_path(current_facility, @account.owner_user)
    else
      render action: "new"
    end
  end

  # GET /facilities/:facility_id/accounts/:id/edit
  def edit
  end

  # PUT /facilities/:facility_id/accounts/:id
  def update
    account_type = Account.config.account_type_to_param(@account.class)

    @account = AccountBuilder.for(account_type).new(
      account: @account,
      current_user: current_user,
      owner_user: @owner_user,
      params: params,
    ).update

    if @account.save
      LogEvent.log(@account, :update, current_user)
      flash[:notice] = I18n.t("controllers.facility_accounts.update")
      redirect_to facility_account_path
    else
      render action: "edit"
    end
  end

  def new_account_user_search
  end

  # GET/POST /facilities/:facility_id/accounts/search_results
  # TODO: use a service object here
  def search_results
    owner_where_clause = <<-end_of_where
      (
        LOWER(users.first_name) LIKE :term
        OR LOWER(users.last_name) LIKE :term
        OR LOWER(users.username) LIKE :term
        OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
      )
      AND account_users.user_role = :acceptable_role
      AND account_users.deleted_at IS NULL
    end_of_where

    term = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length >= 3

      # retrieve accounts matched on user for this facility
      @accounts = Account.joins(account_users: :user).for_facility(current_facility).where(
        owner_where_clause,
        term: term,
        acceptable_role: "Owner",
      ).order("users.last_name, users.first_name")

      # retrieve accounts matched on account_number for this facility
      @accounts += Account.for_facility(current_facility).where(
        "LOWER(account_number) LIKE ?", term)
                          .order("type, account_number",
                                )

      # only show an account once.
      @accounts = @accounts.uniq.paginate(page: params[:page]) # hash options and defaults - :page (1), :per_page (30), :total_entries (arr.length)
    else
      flash.now[:errors] = "Search terms must be 3 or more characters."
    end
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  # GET /facilities/:facility_id/accounts/:account_id/members
  def members
  end

  # GET /facilities/:facility_id/accounts_receivable
  def accounts_receivable
    @account_balances = {}
    order_details = OrderDetail.for_facility(current_facility).complete
    order_details.each do |od|
      @account_balances[od.account_id] = @account_balances[od.account_id].to_f + od.total.to_f
    end
    @accounts = Account.where_ids_in(@account_balances.keys)
  end

  # GET /facilities/:facility_id/accounts/:account_id/statements
  def statements
    @statements = Statement.for_facility(current_facility)
                           .where(account: @account)
                           .paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/accounts/:account_id/statements/:statement_id
  def show_statement
    @statement = Statement.for_facility(current_facility)
                          .where(account: @account)
                          .find(params[:statement_id])

    respond_to do |format|
      format.pdf do
        @statement_pdf = StatementPdfFactory.instance(@statement, download: true)
        render "statements/show"
      end
    end
  end

  private

  def available_account_types
    @available_account_types ||= Account.config.account_types_for_facility(current_facility, :create).select do |account_type|
      current_ability.can?(:create, account_type.constantize)
    end
  end
  helper_method :available_account_types

  def current_account_type
    @current_account_type ||= if available_account_types.include?(params[:account_type])
                                params[:account_type]
                              else
                                available_account_types.first
                              end
  end
  helper_method :current_account_type

  def init_account
    if params.key? :id
      @account = Account.find params[:id].to_i
    elsif params.key? :account_id
      @account = Account.find params[:account_id].to_i
    end
  end

  def build_account
    raise CanCan::AccessDenied if current_account_type.blank?

    @owner_user = User.find(params[:owner_user_id])
    @account = AccountBuilder.for(current_account_type).new(
      account_type: current_account_type,
      facility: current_facility,
      current_user: current_user,
      owner_user: @owner_user,
      params: params,
    ).build
  end

end
