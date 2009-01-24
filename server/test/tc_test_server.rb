lib_path=File.expand_path(File.dirname(__FILE__)+"//..//lib")
$:.unshift(lib_path) unless $:.include?(lib_path)

require 'test/unit'
require 'tndp_server'


TEST_IMAGES_DIR=File.dirname(__FILE__)+"/test_images"

def log_msg(msg)
  puts msg
end
class TestServer <Test::Unit::TestCase

  @@client_socket=UDPSocket.open()
  @@client_socket.connect("localhost",TNDPServer::LISTENING_PORT)
  
  
  def send_request_and_get_response(request)
    puts "###########"
      @@client_socket.send(request.to_buffer,0)
      if (select([@@client_socket],nil,nil,5)).nil? then
        raise "no response from server"
      end
      response_bytes=@@client_socket.recvfrom(4096)[0]
      response=TNDP.message_from_buffer(response_bytes)
      assert_equal(request.transaction_id,response.transaction_id,"transaction id from request should be echoed in response")
      response
  end
  def test_server
    Thread.abort_on_exception = true
    server=TNDPServer.new(TEST_IMAGES_DIR)
    server.start
    capabilities_response_msg=send_request_and_get_response(TNDP::CapabilitiesRequestMessage.new())
    assert(capabilities_response_msg.respond_to?(:supported_architectures),"capabilities response message should include list of architectures supported by server")
    
    assert(capabilities_response_msg.supported_architectures[:apple2]>0,"should be at least 1 apple2 image")
    assert(capabilities_response_msg.supported_architectures[:c64]>0,"should be at least 1 C64 image")
    [[:apple2,:apple_dos_33],[:apple2,:prodos],[:apple2,:any],[:c64,:cbm_dos],[:any,:any],[:any,:prodos]].each do |a|
      desired_system_architecture=a[0]
      desired_file_system=a[1]
      log_msg ("TESTING CATALOG FOR ARCHITECTURE #{desired_system_architecture} / FILE SYSTEM #{desired_file_system}")
    
      done=false
      catalog_offset=0
      while !done do
        volume_catalog_request_msg=TNDP::VolumeCatalogRequestMessage.new({:system_architecture=>desired_system_architecture,:file_system=>desired_file_system,:catalog_offset=>catalog_offset})
        assert_equal(desired_system_architecture,volume_catalog_request_msg.system_architecture)
        assert_equal(desired_file_system,volume_catalog_request_msg.file_system)
        volume_catalog_response_msg=send_request_and_get_response(volume_catalog_request_msg)
        assert(volume_catalog_response_msg.respond_to?(:catalog_entries),"volume catalogue response message should include list of volumes on server")
        assert(volume_catalog_response_msg.catalog_entries.length>0,"volume catalogue response message should have at least 1 entry")
        volume_catalog_response_msg.catalog_entries.each do |entry|
          assert_equal(desired_system_architecture,entry[1],"each entry should be for specified architecture") unless desired_system_architecture==:any
          assert_equal(desired_file_system,entry[2],"each entry should be for specified file system") unless desired_file_system==:any
          volume_name=entry[0]          
          track_no=entry[3]-1 #last track
          sector_no=1
          sector_length=entry[4]
          assert_equal(TNDP::ErrorCodes::INVALID_VOLUME_NAME,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>"invalid file name"})).errorcode,"invalid volume name should return error")
          assert_equal(TNDP::ErrorCodes::INVALID_TRACK_NUMBER,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>0xDEAD,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name})).errorcode,"invalid track number should return error")
          assert_equal(TNDP::ErrorCodes::INVALID_SECTOR_NUMBER,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>0xBEEF,:sector_length=>sector_length,:volume_name=>volume_name})).errorcode,"invalid sector number should return error")
          assert_equal(TNDP::ErrorCodes::INVALID_SECTOR_LENGTH,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>0xD00D,:volume_name=>volume_name})).errorcode,"invalid sector length should return error")

          file_system_image=RipXplore.best_fit_from_filename("#{TEST_IMAGES_DIR}/#{volume_name}")
          sector_read_request_msg=TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name})
          sector_read_response_msg=send_request_and_get_response(sector_read_request_msg)                    
          
          assert(sector_read_response_msg.respond_to?(:sector_data),"sector read response message should include sector data")  
          assert(file_system_image.get_sector(track_no,sector_no)==sector_read_response_msg.sector_data,"data returned from server should match data read directly from disk")
        end
        catalog_offset+=volume_catalog_response_msg.catalog_entries.length
        done=(catalog_offset>volume_catalog_response_msg.total_catalog_size-1)
      end    
    end
    server.shutdown
  end

end