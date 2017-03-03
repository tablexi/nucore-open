Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      facility_product_routing_concern
      resources :price_policies, controller: "secure_room_price_policies", except: :show
    end

    resources :indala_numbers, controller: "secure_rooms/indala_numbers", only: [:edit, :update]
  end
end
