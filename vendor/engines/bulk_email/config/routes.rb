Rails.application.routes.draw do
  resources :facilities, only: [] do
    get "bulk_email", to: "bulk_email#search"
  end
end
