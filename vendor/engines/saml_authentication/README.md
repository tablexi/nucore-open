# SamlAuthentication Engine

NUcore uses [Devise](https://github.com/plataformatec/devise) for authentication,
and uses the [`saml_authenticatable`](https://github.com/apokalipto/devise_saml_authenticatable)
module for SAML integration.

## Enabling SAML Authentication

Add the following line to your `Gemfile` if it is not already present:

```ruby
gem "saml_authentication", path: "vendor/engines/saml_authentication"`
```

In `config/settings.yml`, uncomment the `saml` section and adjust the settings
as necessary to connect with your Identity Provider (IdP).

```yaml
saml:
  idp_metadata: "https://websso.example.com/idp/metadata"
  certificate_file: path/to/file.p12
  attribute_map:
    "PersonImmutableID": "username"
    "User.email": "email"
    "User.FirstName": "first_name"
    "User.LastName": "last_name"
```

* `idp_metadata`: The URL for your IdP's metadata. This should be provided to you by the IdP.
* `certificate_file` (Optional): A `.p12` certificate file for signing your requests.
  _Do not check this in to version control_
* `attribute_map`: A mapping from the IdP's attributes to the NUcore's `users` table
  columns. `username` and `email` are absolutely required while entries for `first_name`
  and `last_name` are recommended.

## Handling Users

When a user logs in one of three things will happen (in this order):

1. If the username field (as specified in `attribute_map`) matches an existing
   NUcore `User`, they will be logged in. Other attributes coming from the SAML
   exchange (`email`, `first_name`, `last_name`) will be updated.
2. If the SAML user's email address matches an existing `User`'s email address,
   the user's `username` will be updated as will other attributes. The user's
   password will be cleared, and they will no longer be able to log in via
   username/password. They will always need to log in via SSO in the future.
3. If the user's username or email does not match an existing a user, a new `User`
   will be created. They will not be able to do much at this point because they
   will have no payment sources. A facility staff/director/administrator will need
   to set that up for them.

_TODO: Determine recommended process for proactive user creation by facility staff_

## Testing and Development

If you do not have full access to your IdP's configuration, [OneLogin](https://www.onelogin.com/)
is a good solution for a free IdP. Use one of their "SAML Test Connector (IdP)"
applications.

OneLogin application configuration:

`settings.yml`'s `idp_metadata` will be something like `https://app.onelogin.com/saml/metadata/123456`

* **Audience:** `http://localhost:3000/users/saml/metadata`
* **Recipient:** `http://localhost:3000/users/saml/auth`
* **ACS (Consumer) URL Validator:** `http:\/\/localhost:3000\/users\/saml\/auth`
* **ACS (Consumer) URL:** `http://localhost:3000/users/saml/auth`
* **Single Logout URL:** `http://localhost:3000/users/saml/idp_sign_out`

## Notes on `saml_authenticatable`

_Coming soon:_ Single Logout is not yet functional.

There are currently monkey patches against the base gem in order to work with NUcore.

[saml_authentication/model.rb](lib/saml_authentication/model.rb) - Allows us to use
our settings file for the attribute map (SAML keys vs User attribute/columns)

[saml_authentication/routes.rb](lib/saml_authentication/routes.rb) - The gem's
routes conflict with the standard Devise database_authenticatable routes.
