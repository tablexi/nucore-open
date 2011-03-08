# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_nucore_session',
  :secret      => '8860ffb8535e98c73a8ec40d2d7a722d14a6ddfa4bd8f9790ffff9edd6f072f652fc2f47cb2bf8030d3d566a541b7751d8f8d2291cc7a78f6bc7781bfd672904'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

# middleware component for handling flash upload authenticity tokens
ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key])
