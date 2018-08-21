# frozen_string_literal: true

# Including class must implement #relay_connection
# Port refers to the outlet, not the IP port
module PowerRelay

  extend ActiveSupport::Concern

  included do
    ## validations
    validates_presence_of :ip, :port, :username, :password
    validates :auto_logout_minutes, presence: { if: :auto_logout }
  end

  ## instance methods
  def control_mechanism
    Relay::CONTROL_MECHANISMS[:relay]
  end

  def connection_options
    options = {}
    options[:username] = username if username.present?
    options[:password] = password if password.present?
    options
  end

  def toggle(status)
    relay_connection.toggle(port, status)
  end

  def query_status
    relay_connection.status(port)
  end

  def relay_connection
    raise NotImplementedError.new("Subclass must define")
  end

end
