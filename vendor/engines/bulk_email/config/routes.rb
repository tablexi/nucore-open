Rails.application.routes.draw do
  resources :facilities, only: [] do
    get "bulk_email", to: "bulk_email/bulk_email#search"
    post "bulk_email/download", to: "bulk_email/bulk_email#download"
  end
end
