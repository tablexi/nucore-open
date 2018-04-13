Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :journals_kfs, only: [:show], controller: "kfs_export"
  end
end
