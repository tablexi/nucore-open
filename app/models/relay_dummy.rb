class RelayDummy < Relay

  def get_status_port(port)
    @active || instrument.current_instrument_status.is_on?
  end

  def activate_port(port)
    @active=true
  end

  def deactivate_port(port)
    @active=false
  end

  def control_mechanism
    CONTROL_MECHANISMS[:timer]
  end
end
