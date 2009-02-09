#
# message formats for Trivial Network Disk Protocol
#
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'tndp'
require 'socket'
require 'LibRipXplore'

  SYSTEM_ARCHITECTURE_TRANSLATIONS={
    "Apple2"=>:apple2,
   "C64"=>:c64,
  }
  FILE_SYSTEM_TRANSLATIONS={
    "AppleDos"=>:apple_dos_33,
    "CbmDos"=>:cbm_dos,
    "RawDisk"=>:raw,
    "ProDos"=>:prodos,
    "AppleCPM"=>:cpm,
  }

VOLUME_CREATION_PARAMATERS={
  :apple2=>["0.chr*request.track_count*request.sector_length*16",RawDisk,A2DskPhysicalOrder,256],
  :c64=>["0.chr*((17*21)+(7*19)+(6*18)+((request.track_count-30)*17))*256",RawDisk,D64,256],
}

class TNDPServer
  LISTENING_PORT=6502
  attr_reader :root_directory,:port ,:server_thread,:socket,:volume_catalog
  def initialize(root_directory,port=LISTENING_PORT)
    @root_directory=root_directory
    @port=port
  end
    
  
  def start
    create_volume_catalog
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
                volume_catalog.each do |entry|
                supported_architectures[entry[1]]=1+TNDP.coalesce(supported_architectures[entry[1]],0)
              end
              response=TNDP::CapabilitiesResponseMessage.new({:supported_architectures=>supported_architectures})
            when TNDP::VolumeCatalogRequestMessage::OPCODE
              catalog_subset=subset_volume_catalog(request.system_architecture,request.file_system)
              catalog_offset=request.catalog_offset
              catalog_entries=catalog_subset[catalog_offset,TNDP::MAX_CATALOG_ENTRIES_PER_MESSAGE]
              response=TNDP::VolumeCatalogResponseMessage.new({:catalog_entries=>catalog_entries,:catalog_offset=>catalog_offset,:total_catalog_size=>catalog_subset.length})
            when TNDP::SectorReadRequestMessage::OPCODE
                file_system_image=nil
                begin
                file_system_image=RipXplore.best_fit_from_filename("#{@root_directory}/#{request.volume_name}")
                rescue Exception=>e
                  response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INVALID_VOLUME_NAME,e.to_s)  
                end
                if !(file_system_image.nil?) then
                  track_no=request.track_no
                  sector_no=request.sector_no
                  sector_length=request.sector_length
                  if (track_no<file_system_image.start_track) || (track_no>file_system_image.end_track)  then
                    response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INVALID_TRACK_NUMBER,"requested track $#{"%X"% track_no} outside allowable range of $#{"%X"% file_system_image.start_track}..$#{"%X"% file_system_image.end_track}")
                  else
                    sector_data=file_system_image.get_sector(track_no,sector_no)
                    if sector_data.nil? then 
                      response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INVALID_SECTOR_NUMBER,"requested sector $#{"%X"% sector_no} not found in track $#{"%X"% track_no}")
                    elsif (sector_data.length)!=sector_length then
                      response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INVALID_SECTOR_LENGTH,"requested track $#{"%X"% track_no}/sector $#{"%X"% sector_no} is of length $#{"%X"% sector_data.length}, not $#{"%X"% sector_length}")
                    else
                      response=TNDP::SectorReadResponseMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>request.volume_name,:sector_data=>sector_data})
                    end
                  end
                end
            when TNDP::CreateVolumeRequestMessage::OPCODE
              volume_file="#{@root_directory}/#{request.volume_name}"
              volume_creation_paramaters=VOLUME_CREATION_PARAMATERS[request.system_architecture]                
              if volume_creation_paramaters.nil? then
                response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::ARCHITECTURE_NOT_SUPPORTED,"create volume requests for #{request.system_architecture} not supported")    
              elsif request.sector_length!=volume_creation_paramaters[3] then
                response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INVALID_SECTOR_LENGTH,"create volume requests for #{request.system_architecture} should have sector length #{volume_creation_paramaters[3]}")    

              else
                  file_bytes=eval(volume_creation_paramaters[0],binding)
                  volume=FileSystemImage.new(file_bytes,volume_creation_paramaters[1],volume_creation_paramaters[2],volume_file)
                  volume.save_as(volume_file)
                  response=TNDP::CreateVolumeResponseMessage.new({:volume_name=>request.volume_name,:system_architecture=>request.system_architecture,:track_count=>request.track_count,:sector_length=>request.sector_length} )
              end              
            else              
              response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::UNKNOWN_OPCODE,"unknown opcode $#{"%02X" % request.opcode}")
          end
          response.transaction_id=request.transaction_id
        rescue Exception=>e        
          response=TNDP::ErrorResponseMessage.create_error_response(data,TNDP::ErrorCodes::INTERNAL_SERVER_ERROR,e.to_s+e.backtrace[0])
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
  
  #return a subset of the total volume catalog that includes just the entries that match the passed in system architecture & file system
  def subset_volume_catalog(system_architecture,file_system)
#    return volume_catalog
    vc=[]
    volume_catalog.each do |entry|
      vc<<entry if (system_architecture==:any || system_architecture==entry[1]) && (file_system==:any || file_system==entry[2])
    end
    vc
  end
  
private

def create_volume_catalog
    @volume_catalog=[]
    Dir.foreach(@root_directory) do |filename|
      if FileSystemImage.is_file_system_image_filename?(filename) then
        begin
        file_system_image=RipXplore.best_fit_from_filename("#{@root_directory}/#{filename}")      
        system_architecture=TNDP.coalesce(SYSTEM_ARCHITECTURE_TRANSLATIONS[file_system_image.image_format.host_system.to_s],:unknown)
        file_system=TNDP.coalesce(FILE_SYSTEM_TRANSLATIONS[file_system_image.file_system.to_s],:unknown)
        start_track=file_system_image.start_track
        puts filename
        @volume_catalog<<[filename,system_architecture,file_system,file_system_image.track_count,file_system_image.get_sector(start_track,0).length]
        rescue Exception=>e        
        #don't stop if anything throws an exception
        log_msg("ERROR: parsing of #{filename} failed:\n"+e.to_s)
        end
      end
    end
  end

end