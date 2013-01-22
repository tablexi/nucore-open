require "net/http"

class Relay < ActiveRecord::Base
  belongs_to :instrument

  validates_presence_of :instrument_id, :on => :update
  validates_uniqueness_of :port, :scope => :ip, :allow_blank => true

  attr_accessible :type, :username, :password, :ip, :port, :auto_logout, :instrument_id

  alias_attribute :host, :ip


  #TODO Change back to normal hash after dropping support for ruby 1.8
  CONTROL_MECHANISMS=ActiveSupport::OrderedHash[
    :manual, nil,
    :timer, 'timer',
    :relay, 'relay'
  ]
  

  # assume port numbering begins at 1 for public functions
  def get_status
    query_status[port - 1]
  end

  def activate
    toggle(port - 1) if !get_status
  end

  def deactivate
    toggle(port - 1) if get_status
  end

  def control_mechanism
    CONTROL_MECHANISMS[:manual]
  end

  private

  # assume port numbering begins at 0 for private functions
  def toggle(port)
    raise 'Including class must define'
  end

  def query_status
    raise 'Including class must define'
  end

  def get_request(path)
    raise Exception.new("Host/IP not defined for relay") if host.blank?
    raise Exception.new("Path not defined for relay") if path.blank?
    
    resp = nil
    # This would make development easier, but it doesn't work in ruby 1.8.7 because
    # HTTP.start doesn't take the seventh opts
    # opts = {}
    # opts[:open_timeout] = 2 if Rails.env.development?
    # Net::HTTP.start(host, nil, nil, nil, nil, nil, opts) { |http|
    Net::HTTP.start(host) do |http|
      req = Net::HTTP::Get.new(path)
      req.basic_auth username, password
      resp = http.request(req)
    end
    resp
  end
end
