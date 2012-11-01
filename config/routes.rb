Nucore::Application.routes.draw do |map|

  match '/users/sign_in.pdf' => redirect('/users/sign_in')
  devise_for :users, :skip => :passwords

  if SettingsHelper.feature_on? :password_update
    match '/users/password/edit_current' => 'user_password#edit_current', :as => 'edit_current_password'
    match '/users/password/reset' => 'user_password#reset', :as => 'reset_password'
    match '/users/password/edit' => 'user_password#edit', :as => 'edit_password'
    match '/users/password/update' => 'user_password#update', :as => 'update_password'
  end

  # The priority is based upon order of creation: first created -> highest priority.

  # authentication
  map.root :controller => "public", :action => "index"
  map.logout_target '/', :controller => 'public', :action => 'index'
  map.switch_back '/switch_back', :controller => 'public', :action => 'switch_back'

  # shared searches
  map.user_search_results '/user_search_results', :controller =>'search', :action => 'user_search_results', :conditions => { :method => :post }

  map.connect        '/facilities/:facility_id/price_group/:price_group_id/account_price_group_members/search_results', :controller =>'account_price_group_members', :action => 'search_results'

  map.user_accounts  '/facilities/:facility_id/accounts/user/:user_id', :controller => 'facility_accounts', :action => 'user_accounts'

  # front-end accounts
  map.resources :accounts, :only => [:index, :show], :member => {:user_search => :get, :transactions => :get, :transactions_in_review => :get} do |account|

    account.resources :account_users, :only => [:new, :destroy, :create, :index], :collection => {:user_search => :get}
    account.resources :statements, :only => [:index]
    account.resources :facilities, :only => [] do |facility|
      facility.resources :statements, :only => [:show]
    end
  end

  # transaction searches
  #match "/accounts/:account_id/transactions" => 'transaction_history#account_history', :as => "account_transaction_history"
  match "/transactions" => 'transaction_history#my_history', :as => "transaction_history"

  # global settings
  resources :affiliates, :except => :show

  map.resources :facilities, :collection => {:list => :get}, :member => {:manage => :get}, :except => [:delete] do |facility|
    facility.resources :products, :only => [:index] do |product|
      product.resources :product_accessories, :as => 'accessories', :only => [:index, :create, :destroy]
    end


    #facility.transactions '/transactions', :controller => 'transaction_history', :action => 'facility_history'
    facility.instrument_statuses 'instrument_statuses', :controller => 'instruments', :action => 'instrument_statuses'
    facility.resources :instruments, :member => {:manage => :get} do |instrument|
      instrument.public_schedule 'public_schedule', :controller => 'instruments', :action => 'public_schedule'

      instrument.schedule 'schedule', :controller => 'instruments', :action => 'schedule'
      instrument.agenda   'agenda',   :controller => 'instruments', :action => 'agenda'
      instrument.status   'status',   :controller => 'instruments', :action => 'instrument_status'
      instrument.switch   'switch',   :controller => 'instruments', :action => 'switch'
      instrument.resources :schedule_rules, :except => [:show]
      instrument.resources :product_access_groups
      instrument.resources :price_policies, :controller => 'instrument_price_policies', :except => [:show]
      instrument.resources :reservations, :only => [:new, :create, :destroy], :controller => 'facility_reservations' do |reservation|
        reservation.edit_admin '/edit_admin', :controller => 'facility_reservations', :action => 'edit_admin', :conditions => {:method => :get}
        reservation.update_admin '/update_admin', :controller => 'facility_reservations', :action => 'update_admin', :conditions => {:method => :put}
      end
      instrument.resources :reservations, :only => [:index]
      instrument.resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      instrument.connect '/users/user_search_results', :controller =>'product_users', :action => 'user_search_results'
      instrument.update_restrictions '/update_restrictions', :controller => 'product_users', :action => 'update_restrictions'
    end

    facility.resources :services, :member => {:manage => :get} do |service|
      service.resources :price_policies, :controller => 'service_price_policies', :except => [:show]
      service.resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      service.connect '/users/user_search_results', :controller =>'product_users', :action => 'user_search_results'
    end

    facility.resources :items, :member => {:manage => :get} do |item|
      item.resources :price_policies, :controller => 'item_price_policies', :except => [:show]
      item.resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      item.connect '/users/user_search_results', :controller =>'product_users', :action => 'user_search_results'
    end

    facility.resources :bundles, :member => {:manage => :get} do |bundle|
      bundle.resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      bundle.connect '/users/user_search_results', :controller =>'product_users', :action => 'user_search_results'
      bundle.resources :bundle_products, :controller => 'bundle_products', :except => [:show]
    end

    facility.resources :general_reports, :collection => {
        :product => [:get, :post],
        :account => [:get, :post],
        :account_owner => [:get, :post],
        :purchaser => [:get, :post],
        :price_group => [:get, :post],
        :assigned_to => [:get, :post]
    }

    facility.resources :instrument_reports, :collection => {
        :instrument => [:get, :post],
        :account => [:get, :post],
        :account_owner => [:get, :post],
        :purchaser => [:get, :post]
    }

    facility.resources :instrument_day_reports, :collection => {
        :actual_quantity => [:get, :post],
        :reserved_quantity => [:get, :post],
        :reserved_hours => [:get, :post],
        :actual_hours => [:get, :post]
    }

    facility.resources :price_group_products, :only => [ :edit, :update ]

    facility.schedule 'schedule', :controller => 'facilities', :action => 'schedule'
    facility.agenda   'agenda',   :controller => 'facilities', :action => 'agenda'
    facility.resources :order_statuses, :except => [:show]

    facility.resources :facility_users, :controller => 'facility_users', :only => [:index, :destroy], :collection => {:search => :get} do |user|
      user.map_user '/map_user', :controller => 'facility_users', :action => 'map_user'
    end

    except=[ :edit, :update ]
    collection={:username_search => :post, :new_search => :get}

    unless SettingsHelper.feature_on?(:create_users)
      except += [ :new, :create ]
      collection.clear
    end

    facility.resources :users, :except => except, :collection => collection do |user|
      user.switch_to   '/switch_to',  :controller => 'users', :action => 'switch_to', :conditions => {:method => :get}
      user.orders       'orders',      :controller => 'users', :action => 'orders'
      user.reservations 'reservations',      :controller => 'users', :action => 'reservations'
      user.accounts     'accounts',    :controller => 'users', :action => 'accounts'
      user.instruments  'instruments', :controller => 'users', :action => 'instruments'
    end

    facility.resources :facility_accounts, :controller => 'facility_facility_accounts', :only => [:index, :new, :create, :edit, :update] if SettingsHelper.feature_on? :recharge_accounts

    facility.resources :orders, :controller => 'facility_orders', :only => [:index, :edit, :update], :member => { :send_receipt => :post }, :collection => {:batch_update => :post, :show_problems => :get, :disputed => :get, :tab_counts => :get } do |order|
      order.resources :order_details, :controller => 'facility_order_details', :only => [:edit, :update, :destroy], :member => {:remove_from_journal => :get} do |order_detail|
        order_detail.new_price '/new_price', :controller => 'facility_order_details', :action => 'new_price', :conditions => {:method => :get}
        order_detail.resolve_dispute '/resolve_dispute', :controller => 'facility_order_details', :action => 'resolve_dispute', :conditions => {:method => :put}
        order_detail.resources :reservations, :controller => 'facility_reservations', :only => [:edit, :update, :show]
      end
    end

    facility.resources :order_imports, :only => [ :new, :create ]

    facility.resources :reservations, :controller => 'facility_reservations', :only => :index, :collection => {:batch_update => :post, :show_problems => :get, :disputed => :get, :timeline => :get, :tab_counts => :get}

    facility.accounts_receivable '/accounts_receivable', :controller => 'facility_accounts', :action => 'accounts_receivable', :conditions => {:method => :get}

    only=[ :index,  :show, ]
    collection={ :search => :get, :search_results => [:get, :post] }
    can_edit_accounts=SettingsHelper.feature_on? :edit_accounts

    if can_edit_accounts
      only += [:new, :create, :edit, :update ]
      collection.merge!(:new_account_user_search => :get, :user_search => :get)
    end

    facility.resources :accounts, :controller => 'facility_accounts', :only => only, :collection => collection do |account|
      account.members '/members', :controller => 'facility_accounts', :action => 'members', :conditions => {:method => :get}
      account.resources :account_users, :controller => 'facility_account_users', :only => [:new, :destroy, :create, :update], :collection => {:user_search => :get} if can_edit_accounts
      account.statement  '/statements/:statement_id.:format', :controller => 'facility_accounts', :action => 'show_statement', :conditions => {:method => :get} if AccountManager.using_statements?

      if SettingsHelper.feature_on? :suspend_accounts
        account.suspend '/suspend', :controller => 'facility_accounts', :action => 'suspend'
        account.unsuspend '/unsuspend', :controller => 'facility_accounts', :action => 'unsuspend'
      end
    end

    facility.resources :journals, :controller => 'facility_journals', :only => [:index, :new, :create, :update, :show] do |journal|
      journal.reconcile '/reconcile', :controller => 'facility_journals', :action => 'reconcile', :conditions => {:method => :post}
    end

    facility.bulk_email '/bulk_email', :controller => 'bulk_email', :action => 'search', :conditions => {:method => :get}
    #resources :bulk_email, :member => { :search => [:get, :post]}, :only => [:search]

    facility.resources :price_groups, :member => {:users => :get, :accounts => :get} do |price_group|
      price_group.resources :user_price_group_members,    :only => [:new, :destroy, :create], :collection => {:create => :get}
      price_group.resources :account_price_group_members, :only => [:new, :destroy, :create], :collection => {:create => :get}
    end

    facility.notifications '/notifications', :controller => 'facility_notifications', :action => 'index', :conditions => {:method => :get}
    facility.send_notifications 'notifications/send', :controller => 'facility_notifications', :action => 'send_notifications', :conditions => {:method => :post }
    facility.transactions '/transactions', :controller => 'facilities', :action => 'transactions', :conditions => {:method => :get}
    facility.notifications_in_review '/in_review', :controller => 'facility_notifications', :action => 'in_review', :conditions => {:method => [:get]}
    facility.notifications_mark_as_reviewed '/in_review/mark', :controller => 'facility_notifications', :action => 'mark_as_reviewed', :conditions => {:method => [:post]}

    facility.resources :statements, :controller => 'facility_statements', :only => [:index, :new, :show, :send_statements], :collection => {:send_statements => :post }
  end

  # order process
  map.cart '/orders/cart', :controller => 'orders', :action => 'cart'

  match "/orders(/:status)" => "orders#index", :status => /pending|all/, :as => "orders_status"
  #match "/orders/all" => "orders#index", :status => "all", :as => "orders_all"
  map.remove_order '/orders/:id/remove/:order_detail_id', :controller => 'orders', :action => 'remove', :conditions => {:method => :put}
  map.add_account '/order/:id/add_account', :controller => 'orders', :action => 'add_account'
  map.resources :orders, :member => {:add => [:get, :put], :purchase => [ :get, :put ], :receipt => :get, :clear => :put, :choose_account => [:get,:post]} do |order|
    order.resources :order_details, :only => [:show, :update] do |order_detail|
      order_detail.order_file '/order_file', :controller => 'order_details', :action => 'order_file', :conditions => {:method => :get}
      order_detail.upload_order_file '/upload_order_file', :controller => 'order_details', :action => 'upload_order_file', :conditions => {:method => :post}
      order_detail.remove_order_file '/remove_order_file', :controller => 'order_details', :action => 'remove_order_file', :conditions => {:method => :get}
      order_detail.resources :reservations, :except => [:index] do |reservation|
        reservation.move_reservation '/move', :controller => 'reservations', :action => 'move', :conditions => {:method => :get}
        reservation.switch_instrument '/switch_instrument', :controller => 'reservations', :action => 'switch_instrument', :conditions => {:method => :get}
        reservation.pick_accessories '/pick_accessories', :controller => 'reservations', :action => 'pick_accessories', :conditions => {:method => [:get, :post]}
      end
    end
  end

  #notifications
  resources :notifications, :only => [ :index ] do
    collection { get :count }
  end

  # reservations
  match 'reservations' => 'reservations#list', :as => 'reservations'
  match "reservations(/:status)" => 'reservations#list', :as => 'reservations_status'

  # file upload routes
  map.upload_product_file '/facilities/:facility_id/:product/:product_id/files/upload',
                          :controller => 'file_uploads', :action => 'upload', :conditions => {:method => :get}
  map.add_product_file    '/facilities/:facility_id/:product/:product_id/files',
                          :controller => 'file_uploads', :action => 'create', :conditions => {:method => :post}
  map.add_uploader_file  '/facilities/:facility_id/:product/:product_id/uploader_files',
                          :controller => 'file_uploads', :action => 'uploader_create', :conditions => {:method => :post}
  map.remove_product_file '/facilities/:facility_id/:product/:product_id/files/:id',
                          :controller => 'file_uploads', :action => 'destroy', :conditions => {:method => :delete}
  map.product_survey '/facilities/:facility_id/:product/:product_id/files/product_survey',
                          :controller => 'file_uploads', :action => 'product_survey', :conditions => {:method => :get}
  map.create_product_survey    '/facilities/:facility_id/:product/:product_id/files/create_product_survey',
                          :controller => 'file_uploads', :action => 'create_product_survey', :conditions => {:method => :post}

  map.activate_survey '/facilities/:facility_id/services/:service_id/surveys/:external_service_passer_id/activate',
                              :controller => 'surveyors', :action => 'activate', :conditions => {:method => :put}
  map.deactivate_survey '/facilities/:facility_id/services/:service_id/surveys/:external_service_passer_id/deactivate',
                                :controller => 'surveyors', :action => 'deactivate', :conditions => {:method => :put}
  map.complete_survey '/facilities/:facility_id/services/:service_id/surveys/:external_service_id/complete',
                                :controller => 'surveyors', :action => 'complete', :conditions => {:method => [:get, :post]}

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
