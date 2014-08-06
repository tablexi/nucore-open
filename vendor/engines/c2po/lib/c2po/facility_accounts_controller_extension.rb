module C2po
  module FacilityAccountsControllerExtension
    extend ActiveSupport::Concern

    included do
      before_filter :set_billing_navigation, only: [:credit_cards, :purchase_orders]
    end

    module ClassMethods
      def billing_access_checked_actions
        [:credit_cards, :update_credit_cards, :purchase_orders, :update_purchase_orders, :accounts_receivable, :show_statement]
      end
    end

    def account_class_params
      params[:account] || params[:credit_card_account] || params[:purchase_order_account] || params[:nufs_account]
    end

    def configure_new_account(account)
      case account
        when PurchaseOrderAccount
          account.expires_at = parse_usa_date(account.expires_at).end_of_day
        when CreditCardAccount
          begin
            account.expires_at = Date.civil(account.expiration_year.to_i, account.expiration_month.to_i).end_of_month.end_of_day
          rescue => e
             account.errors.add(:base, e.message)
          end
        else
          super
      end
    end

    # GET /facilities/:facility_id/accounts/credit_cards
    def credit_cards
      @accounts = CreditCardAccount.need_reconciling(current_facility)
      render_account_reconcile
    end

    #POST /facilities/:facility_id/accounts/update_credit_cards
    def update_credit_cards
      update_account(CreditCardAccount, credit_cards_facility_accounts_path)
    end

    # GET /facilities/:facility_id/accounts/purchase_orders
    def purchase_orders
      @accounts = PurchaseOrderAccount.need_reconciling(current_facility)
      render_account_reconcile
    end

    # POST /facilities/:facility_id/accounts/update_purchase_orders
    def update_purchase_orders
      update_account(PurchaseOrderAccount, purchase_orders_facility_accounts_path)
    end

    private

    def set_selected_account_and_order_details
      @selected = get_selected_account(params[:selected_account])
      @unreconciled_details = get_unreconciled_details
    end

    def render_account_reconcile
      set_selected_account_and_order_details if @accounts.present?
      render 'c2po/reconcile'
    end

    def set_billing_navigation
      @subnav = 'billing_nav'
      @active_tab = 'admin_billing'
    end

    def get_selected_account(selected_id)
      if selected_id.present?
        @accounts.find_by_id(selected_id)
      else
        @accounts.first
      end
    end

    def get_unreconciled_details
      OrderDetail
        .order([:account_id, :statement_id, :order_id, :id])
        .account_unreconciled(current_facility, @selected)
        .paginate(page: params[:page])
    end

    def update_account(model_class, redirect_path)
      @error_fields = {}
      update_details = OrderDetail.find(params[:order_detail].keys)

      OrderDetail.transaction do
        count = 0
        update_details.each do |od|
          od_params = params[:order_detail][od.id.to_s]
          od.reconciled_note=od_params[:notes]

          begin
            if od_params[:reconciled] == '1'
              od.change_status!(OrderStatus.reconciled.first)
              count += 1
            else
              od.save!
            end
          rescue
            @error_fields = {od.id => od.errors.collect { |field,error| field}}
            errors = od.errors.full_messages
            errors = [$!.message] if errors.empty?
            flash.now[:error] = (["There was an error processing the #{model_class.name.underscore.humanize.downcase} payments"] + errors).join("<br />")
            raise ActiveRecord::Rollback
          end
        end

        flash[:notice] = "#{count} payment#{count == 1 ? '' : 's'} successfully reconciled" if count > 0
      end

      redirect_to redirect_path
    end
  end

end
