Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      get :manage, on: :member
      resources :price_policies, controller: "secure_room_price_policies", except: :show
      resources :users, controller: "product_users", except: [:show, :edit, :create]
    end
  end
end
