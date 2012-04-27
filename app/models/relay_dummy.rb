class RelayDummy < Relay

  def get_status_port(port)
    @active
  end

  def activate_port(port)
    @active=true
  end

  def deactivate_port(port)
    @active=false
  end

  def control_mechanism
    'timer'
  end
end
