# frozen_string_literal: true

module Dataprobe

  class Ipio

    attr_reader :ip, :port
    attr_accessor :username, :password

    def initialize(host, options = {})
      @ip = host
      @port = options[:port] || 9100
      @username = (options[:username].presence || "user").ljust(21, "\x00")
      @password = (options[:password].presence || "user").ljust(21, "\x00")
    end

    def toggle(outlet, status)
      mode = status ? 1 : 0
      socket = hello_socket
      write_control_cmd socket, mode, outlet
      raise Dataprobe::Error.new("Error while toggling outlet #{outlet}") unless socket.recv(1) == "\x00"
      status
    ensure
      socket.close
    end

    def status(outlet)
      socket = hello_socket
      write_status_cmd socket
      reply = socket.recv 100
      stats = reply.unpack "C*"
      stats[outlet - 1] == 1
    ensure
      socket.close
    end

    def hex_s(int)
      [int].pack "C"
    end

    private

    def hello_socket
      socket = TCPSocket.new ip, port
      socket.write "hello-000\x00"
      socket
    end

    def update_sequence(socket)
      reply = socket.recv 2
      seq = reply.unpack "s<"         #  Turn the two bytes received into an integer
      seq[0] += 1                     #  add 1 to it and turn it back to two bytes
      seq.pack "s<"
    end

    def write_control_cmd(socket, mode, outlet)
      socket.write "\x03#{username}#{password}\x01\x00#{update_sequence socket}#{hex_s outlet}#{hex_s mode}"
    end

    def write_status_cmd(socket)
      socket.write "\x03#{username}#{password}\x04\x00#{update_sequence socket}"
    end

  end

end
