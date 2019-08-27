module UconnCider
  class Engine < ::Rails::Engine
    isolate_namespace UconnCider

    config.to_prepare do
      ViewHook.add_hook("devise.sessions.new",
                        "login_form",
                        "uconn_cider/login_form")
      ViewHook.remove_hook "devise.sessions.new",
                        "before_login_form",
                        "saml_authentication/sessions/new"
    end
  end
end
