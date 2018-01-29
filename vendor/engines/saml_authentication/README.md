# SamlAuthentication Engine

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication,
and uses the [`saml_authenticatable`](https://github.com/apokalipto/devise_saml_authenticatable)
module for SAML integration.

## Enabling SAML Authentication

Start by making sure the `gem "saml_authentication", path: "vendor/engines/saml_authentication"`
line is present in your Gemfile.

In `config/settings.yml`, uncomment the `saml` section and adjust the settings
as necessary to connect with your IdP.
