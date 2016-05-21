SangerSequencing::Engine.routes.draw do
  resources :submissions, only: [:new]
end
