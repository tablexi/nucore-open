Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :projects, controller: "projects/projects", except: [:destroy]
  end
end
