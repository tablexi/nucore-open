# frozen_string_literal: true

Rails.application.routes.draw do
  resources :facilities, only: [] do
    resources :projects, controller: "projects/projects", except: [:destroy] do
      collection do
        get "inactive"
      end
    end
  end
end
