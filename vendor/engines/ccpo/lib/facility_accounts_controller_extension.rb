module FacilityAccountsControllerExtension
  extend ActiveSupport::Concern


  module ClassMethods
    def billing_access_checked_actions
      [:credit_cards, :update_credit_cards, :purchase_orders, :update_purchase_orders, :accounts_receivable, :show_statement]
    end
  end


  module InstanceMethods
    def account_class_params
      params[:account] || params[:credit_card_account] || params[:purchase_order_account] || params[:nufs_account]
    end

    def configure_new_account(account)
      case account
        when PurchaseOrderAccount
          account.expires_at=parse_usa_date(class_params[:expires_at])
        when CreditCardAccount
          begin
            account.expires_at = Date.civil(class_params[:expiration_year].to_i, class_params[:expiration_month].to_i, -1)
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
    end

    #POST /facilities/:facility_id/accounts/update_credit_cards
    def update_credit_cards
      update_account(CreditCardAccount, credit_cards_facility_accounts_path)
    end

    # GET /facilities/:facility_id/accounts/purchase_orders
    def purchase_orders
      show_account(PurchaseOrderAccount)
    end

    # POST /facilities/:facility_id/accounts/update_purchase_orders
    def update_purchase_orders
      update_account(PurchaseOrderAccount, purchase_orders_facility_accounts_path)
    end
  end

end