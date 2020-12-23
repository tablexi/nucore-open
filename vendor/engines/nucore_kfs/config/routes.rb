Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :journals_kfs, only: [:show], controller: "kfs_export"

    get 'journals_kfs/:id/uch_banner', to: 'kfs_export#uch_banner', as: 'uch_banner'
  end
end
