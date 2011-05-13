class RelaySynaccessRevA
  # Supports Synaccess Models: NP-02
  include Relay

  private

  # So here's the deal... When you hit the switch page (pwrSw1.cgi) nothing happens.
  # It's only when hitting the status page AFTER visiting a swith page that
  # the relay is toggled.  I want to beat the Synaccess devs with a baseball bat.
  def toggle(port)
    get_request("/pwrSw#{port + 1}.cgi")
    get_request("/synOpStatus.shtml")
  end

  def get_status
    resp   = get_request('/synOpStatus.shtml')
    doc    = Nokogiri::HTML(resp.body)
    nodes  = doc.xpath('//img')
    status = []

    nodes.each do |node|
      if node.values[0].match(/^led(off|on).gif$/)
        status[node.parent.parent.xpath('th').first.content.to_i - 1] = $1 == 'on' ? true : false
      end
    end
    status
  end

  def self.to_s
    'Synaccess Revision A'
  end
end
