# frozen_string_literal: true

Rails.application.routes.draw do
  resources :facilities, except: [], path: I18n.t("facilities_downcase") do
    resources :products, only: [] do
      resources :product_certification_requirements, only: [:index, :create, :destroy],
                                                     path: "certification_requirements",
                                                     controller: "nu_research_safety/product_certification_requirements"
    end
    resources :user, only: [] do
      resources :user_research_safety_certifications, only: [:index]
    end
  end
end
