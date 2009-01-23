#
# message formats for Trivial Network Disk Protocol
#
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'tndp'
require 'socket'
require 'RipXplore'

class TNDPServer
  LISTENING_PORT=6502
  attr_reader :root_directory,:port ,:server_thread,:socket
  def initialize(root_directory,port=LISTENING_PORT)
    @root_directory=root_directory
    @port=port
  end
  
  def file_system_images_in_directory
    image_files=[]
    Dir.foreach(@root_directory) do |filename|
      image_files<< RipXplore.best_fit_from_filename("#{@root_directory}/#{filename}") if FileSystemImage.is_file_system_image_filename?(filename)
    end
    image_files
  end
  
  def start
    @server_thread=Thread.start do
      @socket=UDPSocket.open
      @socket.bind("",port)
      log_msg("serving #{root_directory} on UDP port #{port}")
      loop do 
        data,addr_info=@socket.recvfrom(4096)
        client_port=addr_info[1]
        client_ip=addr_info[3]
        log_msg "#{data.length} bytes received from #{client_ip}:#{client_port}"
         begin
          request=TNDP.message_from_buffer(data)
          log_msg(request.to_s)          
          case request.opcode
            when TNDP::CapabilitiesRequestMessage::OPCODE                
                supported_architectures={}
                file_system_images_in_directory.each do |file_system_image|
                if file_system_image.image_format.host_system==Apple2
                then
                  architecture_id=TNDP::SYSTEM_ARCHITECTURES[:apple2 ]
                elsif file_system_image.image_format.host_system==C64 then
                  architecture_id=TNDP::SYSTEM_ARCHITECTURES[:c64]
                else 
                  architecture_id=TNDP::SYSTEM_ARCHITECTURES[:other]
                end
                supported_architectures[architecture_id]=1+TNDP.coalesce(supported_architectures[architecture_id],0)
              end
              response=TNDP::CapabilitiesResponseMessage.new({:supported_architectures=>supported_architectures})
            when TNDP::VolumeCatalogRequestMessage::OPCODE                
              response=TNDP::VolumeCatalogResponseMessage.new() 
            else              
              response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::UNKNOWN_OPCODE,"unknown opcode 0x#{"%02X" % request.opcode}")
          end
          response.transaction_id=request.transaction_id
        rescue Exception=>e        
          response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INTERNAL_SERVER_ERROR,e.to_s)
        end
        log_msg("Response:")
        log_msg(response.to_s)
        @socket.send(response.to_buffer,0,client_ip,client_port)
      end
    end
  end
  
  def shutdown
    log_msg("TNDP server on UDP port #{port} shutting down")
    @server_thread.kill
    
  end
end