SangerSequencing::Engine.routes.draw do
  scope module: "sanger_sequencing" do
    resources :submissions, only: [:new]
  end
end
