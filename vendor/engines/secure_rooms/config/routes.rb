Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      facility_product_routing_concern
      resources :price_policies, controller: "secure_room_price_policies", except: :show
    end

    resources :users do
      get :"card_number/edit", to: "secure_rooms/card_numbers#edit"
      patch :"card_number/update", to: "secure_rooms/card_numbers#update"
    end
  end
end
