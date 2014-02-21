module C2po
  module FacilityAccountsControllerExtension
    extend ActiveSupport::Concern


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
          rescue Exception => e
             account.errors.add(:base, e.message)
          end
        else
          super
      end
    end

    # GET /facilities/:facility_id/accounts/credit_cards
    def credit_cards
      show_account(CreditCardAccount)
      render 'c2po/reconcile'
    end

    #POST /facilities/:facility_id/accounts/update_credit_cards
    def update_credit_cards
      update_account(CreditCardAccount, credit_cards_facility_accounts_path)
    end

    # GET /facilities/:facility_id/accounts/purchase_orders
    def purchase_orders
      show_account(PurchaseOrderAccount)
      render 'c2po/reconcile'
    end

    # POST /facilities/:facility_id/accounts/update_purchase_orders
    def update_purchase_orders
      update_account(PurchaseOrderAccount, purchase_orders_facility_accounts_path)
    end


    private

    def show_account(model_class)
      @subnav     = 'billing_nav'
      @active_tab = 'admin_billing'
      @accounts   = model_class.need_reconciling(current_facility)

      unless @accounts.empty?
        selected_id=params[:selected_account]

        if selected_id.blank?
          @selected=@accounts.first
        else
          @accounts.each{|a| @selected=a and break if a.id == selected_id.to_i }
        end

        @unreconciled_details=OrderDetail.account_unreconciled(current_facility, @selected)
        @unreconciled_details=@unreconciled_details.paginate(:page => params[:page])
      end
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
