require "net/http"

class Relay < ActiveRecord::Base
  belongs_to :instrument

  validates_presence_of :instrument_id, :on => :update
  validates_uniqueness_of :port, :scope => :ip, :allow_blank => true

  attr_accessible :type, :username, :password, :ip, :port, :auto_logout, :instrument_id

  alias_attribute :host, :ip


  CONTROL_MECHANISMS={
    :manual => nil,
    :timer => 'timer',
    :relay => 'relay'
  }


  # assume port numbering begins at 1 for public functions
  def get_status_port(port)
    get_status[port - 1]
  end

  def activate_port(port)
    toggle(port - 1) if !get_status_port(port)
  end

  def deactivate_port(port)
    toggle(port - 1) if get_status_port(port)
  end

  def control_mechanism
    CONTROL_MECHANISMS[:manual]
  end

  private

  # assume port numbering begins at 0 for private functions
  def toggle(port)
    raise 'Including class must define'
  end

  def get_status
    raise 'Including class must define'
  end

  def get_request(path)
    resp = nil
    Net::HTTP.start(host) { |http|
      req = Net::HTTP::Get.new(path)
      req.basic_auth username, password
      resp = http.request(req)
    }
    resp
  end
end
