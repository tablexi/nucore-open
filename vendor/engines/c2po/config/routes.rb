Rails.application.routes.draw do
  match 'facilities/:facility_id/accounts/credit_cards' => 'facility_accounts#credit_cards', :as => 'credit_cards_facility_accounts', :via => :get
  match 'facilities/:facility_id/accounts/update_credit_cards' => 'facility_accounts#update_credit_cards', :as => 'update_credit_cards_facility_accounts', :via => :post
  match 'facilities/:facility_id/accounts/purchase_orders' => 'facility_accounts#purchase_orders', :as => 'purchase_orders_facility_accounts', :via => :get
  match 'facilities/:facility_id/accounts/update_purchase_orders' => 'facility_accounts#update_purchase_orders', :as => 'update_purchase_orders_facility_accounts', :via => :post
end