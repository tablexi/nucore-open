class Relay
  require "net/telnet"
  include Net

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

  def valid_connection?
    begin
      @session = Net::Telnet::new("Host" => @host)
      @session.close
    rescue
      return false
    end
    return true
  end

  def get_status
    buffer = send_request("pshow")

    status = Array.new
    fields = Array.new
    buffer.split("\n").each do |line|
      values = line.split('|')
      next if values.length < 2 or values[0].match(/[-]+/)
      if fields.empty?
        values.each{ |v| fields.push(v.strip.downcase) }
      else
        pstatus = Hash.new
        fields.each_index {|i| pstatus[fields[i]] = values[i].strip}
        status.push(pstatus)
      end
    end
    
    return status
  end 
  
  def get_port_status(port)
    return {'status' => 'on'} if Rails.env.test?
    status = self.get_status
    return status[port - 1]
  end

  def on?(port)
    status = get_port_status(port)
    return status["status"] == "On"
  end

  def activate_port(port)
    switch_port(port, 1)
  end
  
  def deactivate_port(port)
    switch_port(port, 0)
  end

  private

  def switch_port(port, status)
    return if Rails.env.test?
    buffer = send_request("pset #{port} #{status}")
  end

  def send_request(string)
    # the stupid controller don't allow simultaneous telnet logins so we try connecting 3 times
    success = false
    for i in 0..2
      break if success
      begin
        @session = Net::Telnet::new("Host" => @host, "Prompt" => /\n\r>\z/, "Waittime" => 0.15)
        success = true
      rescue
        sleep 0.5
      end
    end

    raise Errno::ETIMEDOUT unless success

    # login
    unless @username.nil?
      begin
        @session.waitfor("Match" => /user\sname:\s\z/)
        @session.puts(@username)
        @session.waitfor("Match" => /password:\s\z/)
        @session.puts(@password)
      rescue
        @session.close
        raise Errno::ETIMEDOUT unless success
      end
    end

    # process the command
    buffer = nil
    begin
      @session.cmd("String" => string) { |line| buffer = line }
    rescue TimeoutError
    ensure
      @session.close
    end
    buffer
  end
end