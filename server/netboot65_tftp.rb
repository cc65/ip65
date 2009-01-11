#
# minimal TFTP server implementation for use with netboot65
#
# Jonno Downes (jonno@jamtronix.com) - January, 2009
# 
#

require 'socket'
class Netboot65TFTPServer

  TFTP_OPCODES={
    1=>'RRQ', #read request
    2=>'WRQ', #write request
    3=>'DATA',
    4=>'ACK',
    5=>'ERROR',
  }
  
  TFTP_ERRORCODES={
   1  =>'File not found.',
   2 =>'Access violation.',
   3 =>'Disk full or allocation exceeded.',
   4  =>'Illegal TFTP operation.',
   5  =>'Unknown transfer ID.',
   6  =>'File already exists.',
   7  =>'No such user.',
  }
  TFTP_MAX_RESENDS=10
  
  attr_reader :bootfile_dir,:port,:server_thread
  def initialize(bootfile_dir,port=69)
    @bootfile_dir=bootfile_dir
    @port=port
    @server_thread=nil
    
  end
  
  def send_error(client_ip,client_port,error_code,error_msg)
    packet=[5,error_code,error_msg,0].pack("nnA#{error_msg.length}c")
    socket=UDPSocket.open.send(packet,0,client_ip,client_port)
    log_msg("sent error #{error_code}:'#{error_msg}' to #{client_ip}:#{client_port}")
  end
  
  def send_file(client_ip,client_port,filename)
    
    client_sock=UDPSocket.open
    client_sock.connect(client_ip,client_port)
    data_to_send=File.open(filename,"rb").read
    blocks_to_send=(data_to_send.length.to_f/512.0).ceil    
    log_msg("sending #{filename} to #{client_ip}:#{client_port} (#{blocks_to_send} blocks)")
    blocks_to_send.times do |block_number|
      block_data=data_to_send[block_number*512,512]
      packet=[3,block_number+1,block_data].pack("nnA*")
      log_msg("sending block #{block_number+1}/#{blocks_to_send} to #{client_ip}:#{client_port} - #{block_data.length} bytes")
      client_sock.send(packet,0,client_ip,client_port)
    end
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
        opcode=data[0,2].unpack("n")[0]
        opcode_description=TFTP_OPCODES[opcode]
        opcode_description="[UNK]" if opcode_description.nil?
        log_msg "TFTP: connect from #{client_ip}:#{client_port} - opcode #{opcode} : #{opcode_description}"
        case opcode
          when 1 : #READ REQUEST
           opcode,filename_and_mode=data.unpack("nA*")
           filename,mode=filename_and_mode.split(0.chr)
           log_msg "RRQ for #{filename} (#{mode})"
           if filename=~/^\./ || filename=~/\.\./ then #looks like something dodgy - either a dotfile or a directory traversal attempt
            send_error(client_ip,client_port,1,"'#{filename}' invalid") 
           else
             full_filename="#{bootfile_dir}/#{filename}"
             if File.file?(full_filename) then
               send_file(client_ip,client_port,full_filename)
            else
              send_error(client_ip,client_port,1,"'#{filename}' not found") 
            end
          end
          else
            send_error(client_ip,client_port,4,"opcode #{opcode} not supported")
          end
        socket.close
      end    
    end
#    @server_thread.join
  end
  
  def shutdown()
    log_msg "TFTP: stopping"
    server_thread.kill
  end
  
end