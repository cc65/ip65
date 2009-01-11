#
# minimal TFTP server implementation for use with netboot65
#
# Jonno Downes (jonno@jamtronix.com) - January, 2009
# 
#

require 'socket'
class Netboot65TFTPServer
  
  attr_reader :bootfile_dir,:port,:server_thread
  def initialize(bootfile_dir,port=6969)
    @bootfile_dir=bootfile_dir
    @port=port
    @server_thread=nil
  end
  
  def start()
    log_msg "TFTP: serving #{bootfile_dir} on port #{port}"
    Socket.do_not_reverse_lookup = true
    @server_thread=Thread.start do

      loop do
        socket=UDPSocket.open
        socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
        log_msg "waiting for TFTP client to connect"
        socket.bind(nil,port)
        data,addr_info=socket.recvfrom(4096)
        client_ip=addr_info[3]
        client_port=addr_info[1]
        log_msg "TFTP: connect from #{client_ip}:#{client_port}"
        socket.close
      end    
    end
    #server_thread.join
  end
  
  def shutdown()
    log_msg "TFTP: stopping"
    server_thread.kill
  end
  
end