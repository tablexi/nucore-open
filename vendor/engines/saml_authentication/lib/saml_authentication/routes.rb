# frozen_string_literal: true

# Override the devise_saml_authenticatable routes because their names conflict
# with the database routes.
# See:
# https://github.com/apokalipto/devise_saml_authenticatable/pull/99
ActionDispatch::Routing::Mapper.class_eval do
  protected

  def devise_saml_authenticatable(mapping, _controllers)
    resource :session, only: [], controller: "saml_authentication/sessions", path: "" do
      get :new, path: "saml/sign_in", as: "new_saml"
      post :create, path: "saml/auth", as: "auth_saml"
      match :destroy, path: "saml/#{mapping.path_names[:sign_out]}", as: "destroy_saml_authenticatable", via: mapping.sign_out_via
      get :metadata, path: "saml/metadata", as: "metadata_saml"
      match :idp_sign_out, path: "saml/idp_sign_out", via: [:get, :post]
    end
  end
end
