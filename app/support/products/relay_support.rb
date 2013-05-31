module Products::RelaySupport
  extend ActiveSupport::Concern

  included do
    has_one  :relay, :dependent => :destroy
    has_many :instrument_statuses, :foreign_key => 'instrument_id'

    accepts_nested_attributes_for :relay

    attr_writer :control_mechanism
    before_validation :init_or_destroy_relay

    validate :check_relay_with_right_type
  end

  # control mechanism for instrument
  def control_mechanism
    return @control_mechanism || self.relay.try(:control_mechanism)
  end

  def current_instrument_status
    instrument_statuses.order('created_at DESC').first
  end

  def has_relay?
    relay && (relay.is_a?(RelayDummy) || relay.ip && relay.port)
  end

  def has_real_relay?
    relay && !relay.is_a?(RelayDummy) && relay.ip && relay.port
  end

  private ###################################

  # this is necessary because when rails builds the attached relay
  # and merges the attributes the relay's class is either:
  #
  # 1) whatever it was before the user changed it (value of type field from db)
  # 2) Relay (the super class needed for STI) (if there was no relay attached to this instrument)
  #
  # in order to validate the relay properly we need to cast it
  # and populate self.errors ourselves
  def check_relay_with_right_type
    # only run this if passed in control_mechanism and relay
    # (if type didn't change, we'll already be running with the proper validations)
    if @control_mechanism and self.relay and self.relay.type_changed?
      return if @control_mechanism == 'manual'

      # transform to right type
      a_relay = self.relay.becomes(self.relay.type.constantize)

      # trigger validation of relay
      a_relay.valid?

      # stuff relay's error messages into self.errors
      a_relay.errors.full_messages.each do |error_msg|
        self.errors[:relay] << error_msg
      end

      return a_relay.valid?
    end
    true
  end

  def init_or_destroy_relay
    if @control_mechanism
      # destroy if manual
      self.relay.destroy if @control_mechanism == 'manual' and self.relay


      # relay_attributes aren't passed in when control_mechanism isn't relay
      # may need to init the relay
      if @control_mechanism == Relay::CONTROL_MECHANISMS[:timer]
        self.relay      ||= RelayDummy.new
        self.relay.type =   'RelayDummy'
      end
    end
    true
  end
end