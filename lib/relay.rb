require "net/http"

module Relay
  def initialize(host, username = nil, password = nil)
    @host     = host
    @username = username
    @password = password
  end

  def host
    @host
  end

  def username
    @username
  end

  def password
    @password
  end

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
    Net::HTTP.start(@host) { |http|
      req = Net::HTTP::Get.new(path)
      req.basic_auth @username, @password
      resp = http.request(req)
    }
    resp
  end
end
