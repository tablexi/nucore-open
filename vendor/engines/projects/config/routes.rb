Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :projects,
              controller: "projects/projects",
              only: %i(create edit index new show update)
  end
end
