ActionController::Routing::Routes.draw do |map|
  map.devise_for :users

  # The priority is based upon order of creation: first created -> highest priority.

  # authentication
  map.root :controller => "public", :action => "index"
  map.login_target '/orders', :controller => 'orders', :action => 'index'
  map.logout_target '/', :controller => 'public', :action => 'index'
  map.switch_back '/switch_back', :controller => 'public', :action => 'switch_back'

  # shared searches
  map.user_search_results '/user_search_results', :controller =>'search', :action => 'user_search_results', :conditions => { :method => :post }

  map.connect        '/facilities/:facility_id/price_group/:price_group_id/account_price_group_members/search_results', :controller =>'account_price_group_members', :action => 'search_results'

  map.user_accounts  '/facilities/:facility_id/accounts/user/:user_id', :controller => 'facility_accounts', :action => 'user_accounts'

  # front-end accounts
  map.resources :accounts, :only => [:index, :show], :member => {:user_search => :get} do |account|
    account.resources :account_users, :only => [:new, :destroy, :create, :index], :collection => {:user_search => :get}
    account.resources :statements, :only => [:index]
    account.resources :facilities, :only => [] do |facility|
      facility.resources :statements, :only => [:show]
    end
  end


  map.resources :facilities, :collection => {:list => :get}, :member => {:manage => :get}, :except => [:delete] do |facility|
    facility.resources :products, :only => [:index]

    facility.resources :instruments, :member => {:manage => :get} do |instrument|
      instrument.schedule 'schedule', :controller => 'instruments', :action => 'schedule'
      instrument.agenda   'agenda',   :controller => 'instruments', :action => 'agenda'
      instrument.status   'status',   :controller => 'instruments', :action => 'status'
      instrument.switch   'switch',   :controller => 'instruments', :action => 'switch'
      instrument.resources :schedule_rules, :except => [:show]
      instrument.resources :price_policies, :controller => 'instrument_price_policies', :except => [:show]
      instrument.resources :reservations, :only => [:new, :create, :destroy], :controller => 'facility_reservations' do |reservation|
        reservation.edit_admin '/edit_admin', :controller => 'facility_reservations', :action => 'edit_admin', :conditions => {:method => :get}
        reservation.update_admin '/update_admin', :controller => 'facility_reservations', :action => 'update_admin', :conditions => {:method => :put}
      end
      instrument.resources :reservations, :only => [:index]
      instrument.resources :users, :controller => 'product_users', :except => [:show, :edit, :create]
      instrument.connect '/users/user_search_results', :controller =>'product_users', :action => 'user_search_results'
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

    facility.resources :reports,  :only => [:index], :collection => {:instrument_utilization => [:get, :post], :product_order_summary => [:get, :post]}
    facility.resources :price_group_products, :only => [ :edit, :update ]

    facility.schedule 'schedule', :controller => 'facilities', :action => 'schedule'
    facility.agenda   'agenda',   :controller => 'facilities', :action => 'agenda'
    facility.resources :order_statuses, :except => [:show]

    facility.resources :facility_users, :controller => 'facility_users', :only => [:index, :destroy], :collection => {:search => :get} do |user|
      user.map_user '/map_user', :controller => 'facility_users', :action => 'map_user'
    end

    facility.resources :users, :except => [:edit, :update], :collection => {:username_search => :post, :new_search => :get} do |user|
      user.switch_to   '/switch_to',  :controller => 'users', :action => 'switch_to', :conditions => {:method => :get}
      user.orders      'orders',      :controller => 'users', :action => 'orders'
      user.accounts    'accounts',    :controller => 'users', :action => 'accounts'
      user.instruments 'instruments', :controller => 'users', :action => 'instruments'
    end

    facility.resources :facility_accounts, :controller => 'facility_facility_accounts', :only => [:index, :new, :create, :edit, :update]

    facility.resources :orders, :controller => 'facility_orders', :only => [:index, :show], :collection => {:batch_update => :post, :show_problems => :get, :disputed => :get} do |order|
      order.resources :order_details, :controller => 'facility_order_details', :only => [:edit, :update ], :member => {:remove_from_journal => :get} do |order_detail|
        order_detail.new_price '/new_price', :controller => 'facility_order_details', :action => 'new_price', :conditions => {:method => :get}
        order_detail.resolve_dispute '/resolve_dispute', :controller => 'facility_order_details', :action => 'resolve_dispute', :conditions => {:method => :put}
        order_detail.resources :reservations, :controller => 'facility_reservations', :only => [:edit, :update, :show]
      end
    end

    facility.resources :accounts, :controller => 'facility_accounts', :only => [:index, :new, :create, :show, :edit, :update], :collection => {:credit_cards => :get, :update_credit_cards => :post, :purchase_orders => :get, :update_purchase_orders => :post, :user_search => :get, :search => :get, :search_results => [:get, :post], :new_account_user_search => :get} do |account|
      account.suspend '/suspend', :controller => 'facility_accounts', :action => 'suspend'
      account.unsuspend '/unsuspend', :controller => 'facility_accounts', :action => 'unsuspend'
      account.resources :account_users, :controller => 'facility_account_users', :only => [:new, :destroy, :create], :collection => {:user_search => :get}
      account.statement  '/statements/:statement_id.:format', :controller => 'facility_accounts', :action => 'show_statement', :conditions => {:method => :get}
      account.members '/members', :controller => 'facility_accounts', :action => 'members', :conditions => {:method => :get}
    end

    facility.resources :journals, :controller => 'facility_journals', :only => [:index, :create, :update, :show], :collection => {:history => :get} do |journal|
      journal.reconcile '/reconcile', :controller => 'facility_journals', :action => 'reconcile', :conditions => {:method => :post}
    end

    facility.resources :price_groups, :member => {:users => :get, :accounts => :get} do |price_group|
      price_group.resources :user_price_group_members,    :only => [:new, :destroy, :create], :collection => {:create => :get}
      price_group.resources :account_price_group_members, :only => [:new, :destroy, :create], :collection => {:create => :get}
    end

    facility.notifications '/notifications', :controller => 'facility_notifications', :action => 'index', :conditions => {:method => [:get, :post]}
    facility.notifications_in_review '/notifications/in_review', :controller => 'facility_notifications', :action => 'in_review', :conditions => {:method => [:get, :post]}
    facility.resources :statements, :controller => 'facility_statements', :only => [:index, :show], :collection => {:email => :post, :accounts_receivable => :get, :pending => :get }
  end

  # order process
  map.cart '/orders/cart', :controller => 'orders', :action => 'cart'
  map.remove_order '/orders/:id/remove/:order_detail_id', :controller => 'orders', :action => 'remove', :conditions => {:method => :put}
  map.add_account '/order/:id/add_account', :controller => 'orders', :action => 'add_account'
  map.resources :orders, :member => {:add => [:get, :put], :purchase => :put, :receipt => :get, :clear => :put, :choose_account => [:get,:post]} do |order|
    order.resources :order_details, :only => [:show, :update] do |order_detail|
      order_detail.order_file '/order_file', :controller => 'order_details', :action => 'order_file', :conditions => {:method => :get}
      order_detail.upload_order_file '/upload_order_file', :controller => 'order_details', :action => 'upload_order_file', :conditions => {:method => :post}
      order_detail.remove_order_file '/remove_order_file', :controller => 'order_details', :action => 'remove_order_file', :conditions => {:method => :get}
      order_detail.resources :reservations, :except => [:index] do |reservation|
        reservation.switch_instrument '/switch_instrument', :controller => 'reservations', :action => 'switch_instrument', :conditions => {:method => :get}
      end
    end
  end

  # file upload routes
  map.upload_product_file '/facilities/:facility_id/:product/:product_id/files/upload',
                          :controller => 'file_uploads', :action => 'upload', :conditions => {:method => :get}
  map.add_product_file    '/facilities/:facility_id/:product/:product_id/files',
                          :controller => 'file_uploads', :action => 'create', :conditions => {:method => :post}
  map.add_uploader_file  '/facilities/:facility_id/:product/:product_id/uploader_files',
                          :controller => 'file_uploads', :action => 'uploader_create', :conditions => {:method => :post}
  map.remove_product_file '/facilities/:facility_id/:product/:product_id/files/:id',
                          :controller => 'file_uploads', :action => 'destroy', :conditions => {:method => :delete}
  map.upload_product_survey_file '/facilities/:facility_id/:product/:product_id/files/survey_upload',
                          :controller => 'file_uploads', :action => 'survey_upload', :conditions => {:method => :get}
  map.add_product_survey_file    '/facilities/:facility_id/:product/:product_id/files/survey_upload',
                          :controller => 'file_uploads', :action => 'survey_create', :conditions => {:method => :post}

  # survey routes
  map.create_order_survey     '/orders/:order_id/details/:od_id/surveys/:survey_code',
                              :controller => 'surveyor', :action => 'create', :conditions => {:method => [:get, :post]}
  map.edit_order_survey       '/orders/:order_id/details/:od_id/surveys/:survey_code/:response_set_code/edit',
                              :controller => 'surveyor', :action => 'edit', :conditions => {:method => [:get]}
  map.show_order_survey       '/orders/:order_id/details/:od_id/surveys/:survey_code/:response_set_code',
                              :controller => 'surveyor', :action => 'show', :conditions => {:method => [:get]}
  map.show_admin_order_survey '/facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/surveys/:survey_code/:response_set_code.:format',
                              :controller => 'surveyor', :action => 'show_admin', :conditions => {:method => [:get]}
  map.preview_service_survey  '/facilities/:facility_id/services/:service_id/surveys/:survey_code/preview',
                              :controller => 'surveyor', :action => 'preview', :conditions => {:method => :get}
  map.activate_service_survey '/facilities/:facility_id/services/:service_id/surveys/:survey_code/activate',
                              :controller => 'service_surveys', :action => 'activate', :conditions => {:method => :put}
  map.deactivate_service_survey '/facilities/:facility_id/services/:service_id/surveys/:survey_code/deactivate',
                                :controller => 'service_surveys', :action => 'deactivate', :conditions => {:method => :put}
end
