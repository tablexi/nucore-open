# frozen_string_literal: true

class InstrumentStatusFetcher

  def initialize(facility)
    @facility = facility
  end

  def statuses
    @instrument_statuses = instruments.map do |instrument|
      instrument_status_for(instrument)
    end
  end

  private

  def instruments
    @facility.instruments.order(:id).includes(:relay).select { |instrument| instrument.relay&.networked_relay? }
  end

  def instrument_status_for(instrument)
    # Always return true/on if the relay feature is disabled
    current_on = SettingsHelper.relays_enabled_for_admin? ? status_of(instrument.relay) : true
    previous_instrument_status = instrument.current_instrument_status
    # if the status hasn't changed, don't create a new status
    if previous_instrument_status && current_on == previous_instrument_status.on?
      previous_instrument_status
    else
      # || false will ensure that the value of is_on is not nil (causes a DB error)
      instrument.instrument_statuses.create!(on: current_on || NUCore::Database.boolean(false))
    end
  rescue => e
    Rails.logger.error e.message
    InstrumentStatus.new(instrument: instrument, error_message: e.message)
  end

  def status_of(relay)
    @cache ||= {}
    # Shared schedules might use the same relay on multiple instruments. In these
    # situations, we only want to fetch the status once.
    key = [relay.ip, relay.ip_port, relay.outlet]

    if @cache.key?(key)
      @cache[key]
    else
      @cache[key] = relay.get_status
    end
  end

end
