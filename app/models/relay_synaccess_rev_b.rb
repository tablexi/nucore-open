class RelaySynaccessRevB < Relay
  # Supports Synaccess Models: NP-02B

  include PowerRelay

  private

  def toggle(port)
    get_request("/cmd.cgi?rly=#{port}")
  end

  def query_status
    resp   = get_request('/status.xml')
    doc    = Nokogiri::XML(resp.body)
    nodes  = doc.xpath('/response/*')

    status = []
    nodes.each do |node|
      if node.name.match(/^rly(\d+)$/)
        status[$1.to_i] = node.content == '1' ? true : false
      end
    end
    status
  end

  def self.to_s
    'Synaccess Revision B'
  end
end
