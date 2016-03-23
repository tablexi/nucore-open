module C2po

  module FacilityAccountsControllerExtension

    extend ActiveSupport::Concern

    included do
      before_filter :set_billing_navigation, only: [:credit_cards, :purchase_orders]
    end

    # Actions appended onto the `check_billing_access` before_filter
    def self.check_billing_access_actions_extension
      [:credit_cards, :update_credit_cards, :purchase_orders, :update_purchase_orders]
    end

    # GET /facilities/:facility_id/accounts/credit_cards
    def credit_cards
      @accounts = CreditCardAccount.need_reconciling(current_facility)
      render_account_reconcile || redirect_to(credit_cards_facility_accounts_path)
    end

    # POST /facilities/:facility_id/accounts/update_credit_cards
    def update_credit_cards
      update_account(CreditCardAccount, credit_cards_facility_accounts_path)
    end

    # GET /facilities/:facility_id/accounts/purchase_orders
    def purchase_orders
      @accounts = PurchaseOrderAccount.need_reconciling(current_facility)
      render_account_reconcile || redirect_to(purchase_orders_facility_accounts_path)
    end

    # POST /facilities/:facility_id/accounts/update_purchase_orders
    def update_purchase_orders
      update_account(PurchaseOrderAccount, purchase_orders_facility_accounts_path)
    end

    private

    def selected_account_not_found?
      @selected.blank? && params[:selected_account].present?
    end

    def set_selected_account_and_order_details
      @selected = get_selected_account(params[:selected_account]) || return
      @unreconciled_details = get_unreconciled_details
      @balance = @selected.unreconciled_total(current_facility, @unreconciled_details)
    end

    def render_account_reconcile
      set_selected_account_and_order_details if @accounts.present?
      return nil if selected_account_not_found?
      render "c2po/reconcile"
    end

    def set_billing_navigation
      @subnav = "billing_nav"
      @active_tab = "admin_billing"
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
        .account_unreconciled(current_facility, @selected)
        .order(%w(
                 order_details.account_id
                 order_details.statement_id
                 order_details.order_id
                 order_details.id))
        .paginate(page: params[:page])
    end

    def update_account(model_class, redirect_path)
      @error_fields = {}
      update_details = OrderDetail.find(params[:order_detail].keys)

      OrderDetail.transaction do
        count = 0
        update_details.each do |od|
          od_params = params[:order_detail][od.id.to_s]
          od.reconciled_note = od_params[:notes]

          begin
            if od_params[:reconciled] == "1"
              od.change_status!(OrderStatus.reconciled.first)
              count += 1
            else
              od.save!
            end
          rescue
            @error_fields = { od.id => od.errors.collect { |field, _error| field } }
            errors = od.errors.full_messages
            errors = [$ERROR_INFO.message] if errors.empty?
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
