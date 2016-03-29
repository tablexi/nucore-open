Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :projects, controller: "Projects::Projects", only: %i(create index new)
  end
end
