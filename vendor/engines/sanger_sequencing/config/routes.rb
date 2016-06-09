# This engine should be mounted at "/" in order to support both the front-end
# /sanger_sequencing/submissions/new and the back end /facilities/xxx/sanger_sequencing/submissions
Rails.application.routes.draw do
  namespace :sanger_sequencing do
    resources :submissions, only: [:new, :show, :edit, :update] do
      get :fetch_ids, on: :member
    end
  end

  resources :facilities, only: [] do
    namespace :sanger_sequencing do
      namespace :admin do
        resources :submissions, only: [:index, :show]
      end
    end
  end
end
