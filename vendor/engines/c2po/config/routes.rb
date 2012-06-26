Rails.application.routes.draw do |map|
  map.resources :facilities do |facility|
    facility.resources :accounts, :controller => 'facility_accounts', :collection => {:credit_cards => :get, :update_credit_cards => :post, :purchase_orders => :get, :update_purchase_orders => :post }
  end
end