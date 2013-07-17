Nucore::Application.routes.draw do
  match '/users/sign_in.pdf' => redirect('/users/sign_in')
  devise_for :users, :skip => :passwords

  if SettingsHelper.feature_on?(:password_update)
    match '/users/password/edit_current', :to => 'user_password#edit_current', :as => 'edit_current_password'
    match '/users/password/reset',        :to => 'user_password#reset',        :as => 'reset_password'
    match '/users/password/edit',         :to => 'user_password#edit',         :as => 'edit_password'
    match '/users/password/update',       :to => 'user_password#update',       :as => 'update_password'
  end

  # root route
  root :to => 'public#index'

  # authentication
  match 'switch_back',   :to => 'public#switch_back'

  # shared searches
  post  '/user_search_results', :to => 'search#user_search_results'
  match '/facilities/:facility_id/price_group/:price_group_id/account_price_group_members/search_results', :to => 'account_price_group_members#search_results'
  match '/facilities/:facility_id/accounts/user/:user_id', :to => 'facility_accounts#user_accounts', :as => 'user_accounts'

  post  'order_search' => 'order_search#index', :as => 'order_search'

  # front-end accounts
  resources :accounts, :only => [:index, :show] do
    member do
      get 'user_search'
      get 'transactions'
      get 'transactions_in_review'
    end

    if SettingsHelper.feature_on? :suspend_accounts
      match 'suspend', :to => 'accounts#suspend', :as => 'suspend'
      match 'unsuspend', :to => 'accounts#unsuspend', :as => 'unsuspend'
    end

    resources :account_users, :only => [:new, :destroy, :create, :index] do
      collection do
        get 'user_search'
      end
    end

    resources :statements, :only => [:index]

    resources :facilities, :only => [] do
      resources :statements, :only => [:show]
    end
  end

  # transaction searches
  match '/transactions', :to => 'transaction_history#my_history', :as => 'transaction_history'

  # global settings
  resources :affiliates, :except => :show

  resources :facilities, :except => [:delete] do
    collection do
      get 'list'
    end

    member do
      get 'manage'
    end

    resources :products, :only => [:index] do
      resources :product_accessories, :only => [:index, :create, :destroy], :path => 'accessories'
    end

    match 'instrument_statuses', :to => 'instruments#instrument_statuses', :as => 'instrument_statuses'

    resources :instruments do
      member do
        get 'manage'
      end

      match 'public_schedule', :to => 'instruments#public_schedule'
      match 'schedule',        :to => 'instruments#schedule'
      match 'agenda',          :to => 'instruments#agenda'
      match 'status',          :to => 'instruments#instrument_status'
      match 'switch',          :to => 'instruments#switch'

      resources :schedule_rules, :except => [:show]
      resources :product_access_groups
      resources :price_policies, :controller => 'instrument_price_policies', :except => [:show]
      resources :reservations, :only => [:new, :create, :destroy], :controller => 'facility_reservations' do
        get 'edit_admin',   :to => 'facility_reservations#edit_admin'
        put 'update_admin', :to => 'facility_reservations#update_admin'
      end

      resources :reservations, :only => [:index]
      resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      match '/users/user_search_results', :to => 'product_users#user_search_results'
      match 'update_restrictions',        :to => 'product_users#update_restrictions'
    end

    resources :services do
      member do
        get 'manage'
      end
      resources :price_policies, :controller => 'service_price_policies', :except => [:show]
      resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      match '/users/user_search_results', :to =>'product_users#user_search_results'
    end

    resources :items do
      member do
        get 'manage'
      end
      resources :price_policies, :controller => 'item_price_policies', :except => [:show]
      resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      match '/users/user_search_results', :to =>'product_users#user_search_results'
    end

    resources :bundles do
      member do
        get 'manage'
      end
      resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      match '/users/user_search_results', :to =>'product_users#user_search_results'
      resources :bundle_products, :controller => 'bundle_products', :except => [:show]
    end

    resources :price_group_products, :only => [:edit, :update]

    match 'schedule', :to => 'facilities#schedule'
    match 'agenda',   :to => 'facilities#agenda'
    resources :order_statuses, :except => [:show]

    resources :facility_users, :controller => 'facility_users', :only => [:index, :destroy] do
      collection do
        get 'search'
      end
      match 'map_user', :to => 'facility_users#map_user'
    end

    ### Feature Toggle Create Users ###
    if SettingsHelper.feature_on?(:create_users)
      resources :users, :except => [:edit, :update] do
        collection do
          get 'new_external'
          post 'search'
        end
        get   'switch_to',    :to => 'users#switch_to'
        match 'orders',       :to => 'users#orders'
        match 'reservations', :to => 'users#reservations'
        match 'accounts',     :to => 'users#accounts'
        match 'instruments',  :to => 'users#instruments'
      end
    else
      resources :users, :except => [:edit, :update, :new, :create], :constraints => {:id => /\d+/} do
        get   'switch_to',    :to => 'users#switch_to'
        match 'orders',       :to => 'users#orders'
        match 'reservations', :to => 'users#reservations'
        match 'accounts',     :to => 'users#accounts'
        match 'instruments',  :to => 'users#instruments'
      end
    end
    ######

    resources :facility_accounts, :controller => 'facility_facility_accounts', :only => [:index, :new, :create, :edit, :update] if SettingsHelper.feature_on? :recharge_accounts

    resources :orders, :controller => 'facility_orders', :only => [:index, :edit, :update, :show] do
      member do
        post 'send_receipt'
      end

      collection do
        post 'batch_update'
        get 'show_problems'
        get 'disputed'
        get 'tab_counts'
      end

      resources :order_details, :controller => 'facility_order_details', :only => [:edit, :update, :destroy] do
        member do
          get 'remove_from_journal'
        end
        get 'new_price', :to => 'facility_order_details#new_price'
        put 'resolve_dispute', :to => 'facility_order_details#resolve_dispute'
        resources :reservations, :controller => 'facility_reservations', :only => [:edit, :update, :show]
        get 'manage', :to => 'order_management/order_details#edit', :on => :member
        put 'manage', :to => 'order_management/order_details#update', :on => :member
        get 'pricing', :to => 'order_management/order_details#pricing', :on => :member
        get 'files', :to => 'order_management/order_details#files', :on => :member
      end
    end

    resources :order_imports, :only => [ :new, :create ]

    resources :reservations, :controller => 'facility_reservations', :only => :index do
      collection do
        post 'batch_update'
        get 'show_problems'
        get 'disputed'
        get 'timeline'
        get 'tab_counts'
      end
    end

    get 'accounts_receivable', :to => 'facility_accounts#accounts_receivable'

    ### Feature Toggle Editing Accounts ###
    if SettingsHelper.feature_on?(:edit_accounts)
      resources :accounts, :controller => 'facility_accounts', :only => [:new, :create, :edit, :update] do
        collection do
          get 'new_account_user_search'
          get 'user_search'
        end
        resources :account_users, :controller => 'facility_account_users', :only => [:new, :destroy, :create, :update] do
          collection do
            get 'user_search'
          end
        end
      end
    end

    resources :accounts, :controller => 'facility_accounts', :only => [:index, :show] do
      collection do
        get 'search'
        match 'search_results', :via => [:get, :post]
      end
      get '/members',                          :to => 'facility_accounts#members',        :as => 'members'
      get '/statements/:statement_id(.:format)', :to => 'facility_accounts#show_statement', :as => 'statement', :defaults => { :format => 'html' } if AccountManager.using_statements?

      if SettingsHelper.feature_on?(:suspend_accounts)
        match 'suspend',   :to => 'facility_accounts#suspend',   :as => 'suspend'
        match 'unsuspend', :to => 'facility_accounts#unsuspend', :as => 'unsuspend'
      end
    end

    ######

    resources :journals, :controller => 'facility_journals', :only => [:index, :new, :create, :update, :show] do
      post 'reconcile', :to => 'facility_journals#reconcile'
    end

    get 'bulk_email', :to => 'bulk_email#search'

    resources :price_groups do
      member do
        get 'users'
        get 'accounts'
      end

      resources :user_price_group_members, :only => [:new, :destroy, :create]

      resources :account_price_group_members, :only => [:new, :destroy, :create]
    end

    get 'notifications',       :to => 'facility_notifications#index'
    post 'notifications/send', :to => 'facility_notifications#send_notifications', :as => 'send_notifications'
    get 'transactions',        :to => 'facilities#transactions'
    get 'in_review',           :to => 'facility_notifications#in_review',          :as => 'notifications_in_review'
    post 'in_review/mark',     :to => 'facility_notifications#mark_as_reviewed',   :as => 'notifications_mark_as_reviewed'

    resources :statements, :controller => 'facility_statements', :only => [:index, :new, :show] do
      collection do
        post 'send_statements'
      end
    end
  end

  # order process
  match '/orders/cart', :to => 'orders#cart', :as => 'cart'
  match "/orders(\/:status)", :to => 'orders#index', :as => 'orders_status', :constraints => { :status => /pending|all/ } ## emacs quoting \/


  put '/orders/:id/remove/:order_detail_id', :to => 'orders#remove',      :as => 'remove_order'
  match '/order/:id/add_account',            :to => 'orders#add_account', :as => 'add_account'

  resources :orders do
    member do
      match 'add',            :via => [:get, :put]
      match 'purchase',       :via => [:get, :put]
      match 'choose_account', :via => [:get, :post]
      put   'update_or_purchase'
      get   'receipt'
      put   'clear'
    end

    resources :order_details, :only => [:show, :update] do
      get  '/order_file',        :to => 'order_details#order_file',        :as => 'order_file'
      post '/upload_order_file', :to => 'order_details#upload_order_file', :as => 'upload_order_file'
      get '/remove_order_file',  :to => 'order_details#remove_order_file', :as => 'remove_order_file'

      resources :reservations, :except => [:index] do
        get '/move',               :to => 'reservations#earliest_move_possible'
        post '/move',              :to => 'reservations#move',              :as => 'move_reservation'
        get '/switch_instrument',  :to => 'reservations#switch_instrument', :as => 'switch_instrument'
      end

      resources :accessories
    end
  end

  # notifications
  resources :notifications, :only => [ :index ] do
    collection do
      get :count
    end
  end

  # reservations
  match 'reservations', :to => 'reservations#list', :as => 'reservations'
  match 'reservations(/:status)', :to => 'reservations#list', :as => 'reservations_status'

  # file upload routes
  get   '/facilities/:facility_id/:product/:product_id/files/upload',                                   :to => 'file_uploads#upload',                :as => 'upload_product_file'
  post  '/facilities/:facility_id/:product/:product_id/files',                                          :to => 'file_uploads#create',                :as => 'add_product_file'
  post  '/facilities/:facility_id/:product/:product_id/uploader_files',                                 :to => 'file_uploads#uploader_create',       :as => 'add_uploader_file'
  match '/facilities/:facility_id/:product/:product_id/files/:id',                                      :to => 'file_uploads#destroy',               :as => 'remove_product_file', :via => :delete
  get   '/facilities/:facility_id/:product/:product_id/files/product_survey',                           :to => 'file_uploads#product_survey',        :as => 'product_survey'
  post  '/facilities/:facility_id/:product/:product_id/files/create_product_survey',                    :to => 'file_uploads#create_product_survey', :as => 'create_product_survey'
  put   '/facilities/:facility_id/services/:service_id/surveys/:external_service_passer_id/activate',   :to => 'surveyors#activate',                 :as => 'activate_survey'
  put   '/facilities/:facility_id/services/:service_id/surveys/:external_service_passer_id/deactivate', :to => 'surveyors#deactivate',               :as => 'deactivate_survey'
  match '/facilities/:facility_id/services/:service_id/surveys/:external_service_id/complete',          :to => 'surveyors#complete',                 :as => 'complete_survey',     :via => [:get, :post]

  # general reports
  match '/facilities/:facility_id/general_reports/assigned_to',   :to => 'general_reports#assigned_to',   :as => 'assigned_to_facility_general_reports',   :via => [ :get, :post ]
  match '/facilities/:facility_id/general_reports/account',       :to => 'general_reports#account',       :as => 'account_facility_general_reports',       :via => [ :get, :post ]
  match '/facilities/:facility_id/general_reports/price_group',   :to => 'general_reports#price_group',   :as => 'price_group_facility_general_reports',   :via => [ :get, :post ]
  match '/facilities/:facility_id/general_reports/account_owner', :to => 'general_reports#account_owner', :as => 'account_owner_facility_general_reports', :via => [ :get, :post ]
  match '/facilities/:facility_id/general_reports/product',       :to => 'general_reports#product',       :as => 'product_facility_general_reports',       :via => [ :get, :post ]
  match '/facilities/:facility_id/general_reports/purchaser',     :to => 'general_reports#purchaser',     :as => 'purchaser_facility_general_reports',     :via => [ :get, :post ]

  # instrument reports
  match '/facilities/:facility_id/instrument_reports/account',       :to => 'instrument_reports#account',       :as => 'account_facility_instrument_reports',       :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_reports/account_owner', :to => 'instrument_reports#account_owner', :as => 'account_owner_facility_instrument_reports', :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_reports/instrument',    :to => 'instrument_reports#instrument',    :as => 'instrument_facility_instrument_reports',    :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_reports/purchaser',     :to => 'instrument_reports#purchaser',     :as => 'purchaser_facility_instrument_reports',     :via => [ :get, :post ]

  # instrument day reports
  match '/facilities/:facility_id/instrument_day_reports/actual_quantity',   :to => 'instrument_day_reports#actual_quantity',   :as => 'actual_quantity_facility_instrument_day_reports',   :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_day_reports/reserved_quantity', :to => 'instrument_day_reports#reserved_quantity', :as => 'reserved_quantity_facility_instrument_day_reports', :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_day_reports/reserved_hours',    :to => 'instrument_day_reports#reserved_hours',    :as => 'reserved_hours_facility_instrument_day_reports',    :via => [ :get, :post ]
  match '/facilities/:facility_id/instrument_day_reports/actual_hours',      :to => 'instrument_day_reports#actual_hours',      :as => 'actual_hours_facility_instrument_day_reports',      :via => [ :get, :post ]

end
