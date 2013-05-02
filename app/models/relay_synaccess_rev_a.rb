class RelaySynaccessRevA < Relay
  # Supports Synaccess Models: NP-02

  include PowerRelay

  private

  def self.to_s
    'Synaccess Revision A'
  end

  def relay_connection
    clazz = "#{Settings.relays.connect_module}::RevA".constantize
    @relay_connection ||= clazz.new(host, connection_options)
  end
end
