Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      facility_product_routing_concern
      resources :price_policies, controller: "secure_room_price_policies", except: :show
      resources :users, controller: "product_users", except: [:show, :edit, :create]
      get ":product/:product_id/files/upload", to: 'file_uploads#upload'
    end
  end
end
