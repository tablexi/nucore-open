Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      facility_product_routing_concern
      resources :price_policies, controller: "secure_room_price_policies", except: :show
    end
  end
end
