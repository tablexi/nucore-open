# frozen_string_literal: true

Rails.application.routes.draw do
  resources :facilities, only: [] do
    get "bulk_email", to: "bulk_email/bulk_email#search"
    post "bulk_email", to: "bulk_email/bulk_email#create"
    post "bulk_email/deliver", to: "bulk_email/bulk_email#deliver"

    get "bulk_email/jobs", to: "bulk_email/jobs#index"
    get "bulk_email/job/:id", to: "bulk_email/jobs#show", as: "bulk_email_job"
  end
end
