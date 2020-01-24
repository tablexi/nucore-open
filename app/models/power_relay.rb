# frozen_string_literal: true

# Including class must implement #relay_connection
module PowerRelay

  extend ActiveSupport::Concern

  MAXIMUM_OUTLETS = 16

  included do
    ## validations
    validates_presence_of :ip, :outlet, :username, :password
    validates :auto_logout_minutes, presence: { if: :auto_logout }
    validates :outlet, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAXIMUM_OUTLETS }
    validates :ip_port, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  end

  ## instance methods
  def control_mechanism
    Relay::CONTROL_MECHANISMS[:relay]
  end

  def connection_options
    options = {}
    options[:username] = username if username?
    options[:password] = password if password?
    options[:port] = ip_port if ip_port?
    options
  end

  def toggle(status)
    log_power_relay_connection(:toggle) do
      relay_connection.toggle(outlet, status)
    end
  end

  def query_status
    log_power_relay_connection(:status) do
      relay_connection.status(outlet)
    end
  end

  def relay_connection
    raise NotImplementedError.new("Subclass must define")
  end

  private

  def log_power_relay_connection(event_type)
    ActiveSupport::Notifications.instrument("#{event_type}.power_relays") do |payload|
      payload.merge!(log_power_relay_options)
      begin
        payload[:status] = yield
      rescue => e
        payload[:status] = e
        raise e
      end
    end
  end

  def log_power_relay_options
    {
      options: {
        instrument: instrument.name,
        type: type,
        host: host,
        ip_port: ip_port,
        outlet: outlet,
      }.merge(connection_options.except(:username, :password))
    }
  end

end
