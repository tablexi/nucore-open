class FacilityAccountsReconciliationController < ApplicationController

  include DateHelper

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_billing_access
  before_action :set_billing_navigation
  # before_action { @accounts = account_class.need_reconciling(current_facility) }

  class SearchForm
    include ActiveModel::Model

    attr_accessor :accounts, :account_owners, :statements

    def self.model_name
      ActiveModel::Name.new(self, nil, "Search")
    end

    def [](key)
      public_send(key)
    end

  end

  class TransactionSearcherResults
    attr_reader :order_details
    def initialize(order_details, search_options)
      @order_details = order_details
      @search_options = search_options.freeze
    end

    def options
      @search_options.dup
    end
  end

  class TransactionSearcher
    def initialize(*searchers)
      @searchers = Array(searchers)
    end

    def search(order_details, params)
      @searchers.reduce(TransactionSearcherResults.new(order_details, [])) do |results, searcher_class|
        searcher = searcher_class.new(results.order_details)
        non_optimized = searcher.search(Array(params[searcher_class.key.to_sym]).reject(&:blank?))
        optimized_order_details = searcher_class.new(non_optimized).optimized

        # Options should not be restricted, they should search over the full order details
        option_searcher = searcher_class.new(order_details)

        TransactionSearcherResults.new(
          optimized_order_details,
          results.options + [option_searcher],
        )
      end
    end
  end

  def index
    order_details = OrderDetail.complete
                               .statemented(current_facility)
                               .joins(:account)
                               .where(accounts: { type: account_class })
                               .includes(:order, :product, :statement)

    @search_form = SearchForm.new(params[:search])
    @search = TransactionSearcher.new(
      TransactionSearch::AccountSearcher,
      TransactionSearch::AccountOwnerSearcher,
      TransactionSearch::StatementSearcher,
    ).search(order_details, @search_form)

    @unreconciled_details = @search.order_details.paginate(page: params[:page])
  end

  def update
    update_account
    redirect_to([account_route, :facility_accounts])
  end

  private

  def set_billing_navigation
    @subnav = "billing_nav"
    @active_tab = "admin_billing"
  end

  def account_route
    Account.config.account_type_to_route(params[:account_type])
  end
  helper_method :account_route

  # def selected_account
  #   @selected_account ||= if params[:selected_account].present?
  #                           @accounts.find_by(id: params[:selected_account])
  #                         else
  #                           @accounts.first
  #   end
  # end

  def account_class
    # This is coming in from the router, not the user, so it should be safe
    params[:account_type].constantize
  end
  helper_method :account_class

  # def unreconciled_details
  #   OrderDetail
  #     .account_unreconciled(current_facility, selected_account)
  #     .order(
  #       %w(
  #         order_details.account_id
  #         order_details.statement_id
  #         order_details.order_id
  #         order_details.id
  #       ),
  #     )
  #     .paginate(page: params[:page])
  # end

  # def update_account
  #   reconciled_at = parse_usa_date(params[:reconciled_at])
  #   reconciler = OrderDetails::Reconciler.new(unreconciled_details, params[:order_detail], reconciled_at)

  #   if reconciler.reconcile_all > 0
  #     count = reconciler.count
  #     flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully reconciled" if count > 0
  #   else
  #     flash[:error] = reconciler.full_errors.join("<br />").html_safe
  #   end
  # end

end
