# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.

# TXI Note: If we go straight to :json, then any existing cookies will cause 500s when trying to
# unserialize them. :hybrid can be used to transition.
# In the add to cart logic (OrdersController#add and #choose_account), we rely on
# serializing ActionController::Parameters, so without serious refactoring, we can't
# use :json/:hybrid.
Rails.application.config.action_dispatch.cookies_serializer = :marshal
