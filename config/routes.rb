Nucore::Application.routes.draw do
  match "/users/sign_in.pdf" => redirect("/users/sign_in")
  devise_for :users
  mount SangerSequencing::Engine => "/sanger_sequencing" if defined?(SangerSequencing)

  if SettingsHelper.feature_on?(:password_update)
    match "/users/password/edit_current", to: 'user_password#edit_current', as: "edit_current_password"
    match "/users/password/reset",        to: 'user_password#reset',        as: "reset_password"
    match "/users/password/edit",         to: 'user_password#edit',         as: "edit_password"
    match "/users/password/update",       to: 'user_password#update',       as: "update_password"
  end

  # root route
  root to: 'public#index'

  # authentication
  match "switch_back", to: 'public#switch_back'

  # shared searches
  post  "/user_search_results", to: 'search#user_search_results'
  match "/#{I18n.t("facilities_downcase")}/:facility_id/price_group/:price_group_id/account_price_group_members/search_results", to: 'account_price_group_members#search_results'
  match "/#{I18n.t("facilities_downcase")}/:facility_id/accounts/user/:user_id", to: 'facility_accounts#user_accounts', as: "user_accounts"

  post "global_search" => 'global_search#index', as: "global_search"

  # front-end accounts
  resources :accounts, only: [:index, :show] do
    member do
      get "user_search"
      get "transactions"
      get "transactions_in_review"
    end

    if SettingsHelper.feature_on? :suspend_accounts
      match "suspend", to: 'accounts#suspend', as: "suspend"
      match "unsuspend", to: 'accounts#unsuspend', as: "unsuspend"
    end

    resources :account_users, only: [:new, :destroy, :create, :index] do
      collection do
        get "user_search"
      end
    end

    resources :facilities, only: [], path: I18n.t("facilities_downcase") do
      resources :statements, only: [:show]
    end
  end

  # transaction searches
  match "/transactions", to: 'transaction_history#my_history', as: "transaction_history"

  resources :facilities, except: [:delete], path: I18n.t("facilities_downcase") do
    collection do
      get "list"
    end

    member do
      get "manage"
    end

    resources :products, only: [:index] do
      resources :product_accessories, only: [:index, :create, :destroy], path: "accessories"
      resources :training_requests, only: [:new, :create] if SettingsHelper.feature_on?(:training_requests)
    end

    match "instrument_statuses", to: 'instruments#instrument_statuses', as: "instrument_statuses"

    resources :training_requests, only: [:index, :destroy] if SettingsHelper.feature_on?(:training_requests)

    resources :instruments do
      member do
        get "manage"
      end

      match "public_schedule", to: 'instruments#public_schedule'
      match "schedule",        to: 'instruments#schedule'
      match "status",          to: 'instruments#instrument_status'
      match "switch",          to: 'instruments#switch'

      resources :schedule_rules, except: [:show]
      resources :product_access_groups
      resources :price_policies, controller: "instrument_price_policies", except: [:show]
      resources :reservations, only: [:new, :create, :destroy], controller: "facility_reservations" do
        get "edit_admin",   to: 'facility_reservations#edit_admin'
        put "update_admin", to: 'facility_reservations#update_admin'
      end

      resources :reservations, only: [:index]
      resources :users, controller: "product_users", except: [:show, :edit, :create]
      match "/users/user_search_results", to: 'product_users#user_search_results'
      match "update_restrictions",        to: 'product_users#update_restrictions'
    end

    resources :services do
      member do
        get "manage"
      end
      resources :price_policies, controller: "service_price_policies", except: [:show]
      resources :users, controller: "product_users", except: [:show, :edit, :create]
      match "/users/user_search_results", to: 'product_users#user_search_results'
    end

    resources :items do
      member do
        get "manage"
      end
      resources :price_policies, controller: "item_price_policies", except: [:show]
      resources :users, controller: "product_users", except: [:show, :edit, :create]
      match "/users/user_search_results", to: 'product_users#user_search_results'
    end

    resources :bundles do
      member do
        get "manage"
      end
      resources :users, controller: "product_users", except: [:show, :edit, :create]
      match "/users/user_search_results", to: 'product_users#user_search_results'
      resources :bundle_products, controller: "bundle_products", except: [:show]
    end

    resources :price_group_products, only: [:edit, :update]

    resources :order_statuses, except: [:show]

    resources :facility_users, controller: "facility_users", only: [:index, :destroy], path: "#{I18n.t("facility_downcase")}_users" do
      collection do
        get "search"
      end
      match "map_user", to: 'facility_users#map_user'
    end

    ### Feature Toggle Create Users ###
    if SettingsHelper.feature_on?(:create_users)
      resources :users, except: [:edit, :update] do
        collection do
          get "new_external"
          post "search"
        end
        get   "switch_to",    to: 'users#switch_to'
        match "orders",       to: 'users#orders'
        match "reservations", to: 'users#reservations'
        match "accounts",     to: 'users#accounts'
        match "access_list",  to: 'users#access_list'
        post  "access_list/approvals", to: 'users#access_list_approvals'
      end
    else
      resources :users, except: [:edit, :update, :new, :create], constraints: { id: /\d+/ } do
        get   "switch_to",    to: 'users#switch_to'
        match "orders",       to: 'users#orders'
        match "reservations", to: 'users#reservations'
        match "accounts",     to: 'users#accounts'
        match "access_list",  to: 'users#access_list'
        post  "access_list/approvals", to: 'users#access_list_approvals'
      end
    end
    ######

    if SettingsHelper.feature_on? :recharge_accounts
      resources :facility_accounts, controller: "facility_facility_accounts",
        only: [:index, :new, :create, :edit, :update], path: "#{I18n.t("facility_downcase")}_accounts"
    end

    resources :orders, controller: "facility_orders", only: [:index, :update, :show] do
      member do
        post "send_receipt"
      end

      collection do
        post "assign_price_policies_to_problem_orders"
        post "batch_update"
        get "show_problems"
        get "disputed"
        get "tab_counts"
      end

      resources :order_details, controller: "facility_order_details", only: [:show, :destroy] do
        resources :reservations, controller: "facility_reservations", only: [:edit, :update, :show]
        resources :accessories, only: [:new, :create]
        member do
          get "manage", to: 'order_management/order_details#edit'
          put "manage", to: 'order_management/order_details#update'
          get "pricing", to: 'order_management/order_details#pricing'
          get "files", to: 'order_management/order_details#files'
          post "remove_from_journal", to: 'order_management/order_details#remove_from_journal'
          get "sample_results/:stored_file_id", to: 'order_management/order_details#sample_results', as: "sample_results"
          get "template_results/:stored_file_id", to: 'order_management/order_details#template_results', as: "template_results"
        end
      end
    end

    resources :order_imports, only: [:new, :create] do
      get "error_report", to: "order_imports#error_report", on: :member
    end

    resources :reservations, controller: "facility_reservations", only: :index do
      collection do
        post "assign_price_policies_to_problem_orders"
        post "batch_update"
        get "show_problems"
        get "disputed"
        get "timeline"
        get "tab_counts"
      end
    end

    get "public_timeline", to: 'reservations#public_timeline', as: "public_timeline" if SettingsHelper.feature_on?(:daily_view)
    get "accounts_receivable", to: 'facility_accounts#accounts_receivable'

    ### Feature Toggle Editing Accounts ###
    if SettingsHelper.feature_on?(:edit_accounts)
      resources :accounts, controller: "facility_accounts", only: [:new, :create, :edit, :update] do
        collection do
          get "new_account_user_search"
          get "user_search"
        end
        resources :account_users, controller: "facility_account_users", only: [:new, :destroy, :create, :update] do
          collection do
            get "user_search"
          end
        end
      end
    end

    resources :accounts, controller: "facility_accounts", only: [:index, :show] do
      collection do
        get "search"
        match "search_results", via: [:get, :post]
      end
      get "/members", to: 'facility_accounts#members', as: "members"

      get "/statements/:statement_id(.:format)", to: 'facility_accounts#show_statement', as: "statement", defaults: { format: "html" } if Account.config.statements_enabled?

      # Dynamically add routes like credit_cards and purchase_orders
      Account.config.reconcilable_account_types.each do |type|
        plural_name = Account.config.account_type_to_route(type)
        get plural_name, to: "facility_accounts_reconciliation#index", on: :collection, account_type: type
        post "update_#{plural_name}", to: "facility_accounts_reconciliation#update", on: :collection, account_type: type
      end

      if SettingsHelper.feature_on?(:suspend_accounts)
        match "suspend",   to: 'facility_accounts#suspend',   as: "suspend"
        match "unsuspend", to: 'facility_accounts#unsuspend', as: "unsuspend"
      end

      resources :orders, controller: "facility_account_orders", only: [:index]
    end

    ######

    resources :journals, controller: "facility_journals", only: [:index, :new, :create, :update, :show] do
      post "reconcile", to: 'facility_journals#reconcile'
    end

    get "bulk_email", to: 'bulk_email#search'

    resources :price_groups do
      member do
        get "users"
        get "accounts"
      end

      resources :user_price_group_members, only: [:new, :destroy, :create]

      resources :account_price_group_members, only: [:new, :destroy, :create]
    end

    get "disputed_orders", to: "facilities#disputed_orders"
    get "notifications",       to: 'facility_notifications#index'
    post "notifications/send", to: 'facility_notifications#send_notifications', as: "send_notifications"
    get "transactions",        to: 'facilities#transactions'
    get "in_review",           to: 'facility_notifications#in_review',          as: "notifications_in_review"
    post "in_review/mark",     to: 'facility_notifications#mark_as_reviewed',   as: "notifications_mark_as_reviewed"
    get "movable_transactions", to: 'facilities#movable_transactions'
    post "movable_transactions/reassign_chart_strings", to: 'facilities#reassign_chart_strings'
    post "movable_transactions/confirm", to: 'facilities#confirm_transactions'
    post "movable_transactions/move", to: 'facilities#move_transactions'

    resources :statements, controller: "facility_statements", only: [:index, :new, :show] do
      collection do
        post "send_statements"
      end
    end

    get "general_reports/raw", to: "reports/export_raw_reports#export_all", as: "export_raw_reports"
    get "general_reports/:report_by", to: "reports/general_reports#index", as: "general_reports"
    get "instrument_reports/:report_by", to: "reports/instrument_reports#index", as: "instrument_reports"
    get "instrument_day_reports/:report_by",   to: 'reports/instrument_day_reports#index',   as: "instrument_day_reports"
  end

  # global settings
  resources :affiliates, except: :show
  resources :journal_cutoff_dates
  resources :global_user_roles do
    get "search", on: :collection
  end

  # order process
  match "/orders/cart", to: 'orders#cart', as: "cart"
  match "/orders(\/:status)", to: 'orders#index', as: "orders_status", constraints: { status: /pending|all/ } ## emacs quoting \/

  put "/orders/:id/remove/:order_detail_id", to: 'orders#remove',      as: "remove_order"
  match "/order/:id/add_account",            to: 'orders#add_account', as: "add_account"

  resources :orders do
    member do
      match "add",            via: [:get, :put]
      match "purchase",       via: [:get, :put]
      match "choose_account", via: [:get, :post]
      match "update_or_purchase", via: [:get, :put]
      get   "receipt"
      put   "clear"
    end

    resources :order_details, only: [:show, :edit, :update] do
      put :cancel, on: :member
      put :dispute, on: :member
      get :order_file
      post :upload_order_file
      get :remove_order_file
      get "sample_results/:stored_file_id", to: "order_details#sample_results", as: "sample_results"
      get "template_results/:stored_file_id", to: "order_details#template_results", as: "template_results"

      resources :reservations, except: [:index] do
        get "/move",               to: 'reservations#earliest_move_possible'
        post "/move",              to: 'reservations#move',              as: "move_reservation"
        get "/switch_instrument",  to: 'reservations#switch_instrument', as: "switch_instrument"
      end

      resources :accessories, only: [:new, :create]
    end
  end

  # notifications
  resources :notifications, only: [:index] do
    collection do
      get :count
    end
  end

  # reservations
  match "reservations", to: 'reservations#list', as: "reservations"
  match "reservations(/:status)", to: 'reservations#list', as: "reservations_status"

  # file upload routes
  get   "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files/upload",                                   to: 'file_uploads#upload',                as: "upload_product_file"
  post  "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files",                                          to: 'file_uploads#create',                as: "add_product_file"
  post  "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/uploader_files",                                 to: 'file_uploads#uploader_create',       as: "add_uploader_file"
  match "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files/:id",                                      to: 'file_uploads#destroy',               as: "remove_product_file", via: :delete
  get   "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files/:file_type/:id",                           to: 'file_uploads#download',              as: "download_product_file"
  get   "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files/product_survey",                           to: 'file_uploads#product_survey',        as: "product_survey"
  post  "/#{I18n.t("facilities_downcase")}/:facility_id/:product/:product_id/files/create_product_survey",                    to: 'file_uploads#create_product_survey', as: "create_product_survey"
  put   "/#{I18n.t("facilities_downcase")}/:facility_id/services/:service_id/surveys/:external_service_passer_id/activate",   to: 'surveys#activate',                 as: "activate_survey"
  put   "/#{I18n.t("facilities_downcase")}/:facility_id/services/:service_id/surveys/:external_service_passer_id/deactivate", to: 'surveys#deactivate',               as: "deactivate_survey"
  match "/#{I18n.t("facilities_downcase")}/:facility_id/services/:service_id/surveys/:external_service_id/complete",          to: 'surveys#complete',                 as: "complete_survey", via: [:get, :post]

  # api
  namespace :api do
    resources :order_details, only: [:show]
  end
end
