require "net/http"

class Relay < ActiveRecord::Base
  belongs_to :instrument, :inverse_of => :relay

  validates_presence_of :instrument_id, :on => :update
  validate :unique_ip

  attr_accessible :type, :username, :password, :ip, :port, :auto_logout, :auto_logout_minutes, :instrument_id

  alias_attribute :host, :ip


  CONTROL_MECHANISMS = {
    manual: nil,
    timer: 'timer',
    relay: 'relay'
  }


  def get_status
    query_status
  end

  def activate
    toggle(true)
  end

  def deactivate
    toggle(false)
  end

  def control_mechanism
    CONTROL_MECHANISMS[:manual]
  end

  private

  def toggle(status)
    raise NotImplementedError.new('Subclass must define')
  end

  def query_status
    raise NotImplementedError.new('Subclass must define')
  end

  def unique_ip
    return unless ip.present?
    scope = Relay.unscoped.where(ip: ip, port: port)
    scope = scope.joins(:instrument).where("products.schedule_id != ?", instrument.schedule_id) if instrument.try(:schedule_id)
    scope = scope.where('relays.id != ?', id) if persisted?
    if scope.exists?
      errors.add :port, :taken
    end
  end
end
