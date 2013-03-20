class RelaySynaccessRevB < Relay
  # Supports Synaccess Models: NP-02B

  include PowerRelay

  private

  def self.to_s
    'Synaccess Revision B'
  end

  def relay_connection
    clazz = "#{Settings.relays.connect_module}::RevB".constantize
    @relay_connection ||= clazz.new(host, connection_options)
  end
end
