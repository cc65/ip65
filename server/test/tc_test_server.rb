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
    [
      [:apple2,'SCRATCH_TEST.DSK',35,256],
      [:apple2,'SCRATCH_TEST2.DO',40,256],
      [:c64,'SCRATCH_TEST.D64',35,256],
      [:c64,'SCRATCH_TEST2.D64',40,256],
    ].each do |a|
    #try to make a new blank disk    
      system_architecture=a[0]
      volume_name=a[1]
      track_count=a[2]
      sector_length=a[3]
      image_full_path="#{TEST_IMAGES_DIR}\\#{volume_name}"
      File.delete(image_full_path) if File.exist?(image_full_path)
      create_volume_request_msg=TNDP::CreateVolumeRequestMessage.new({:volume_name=>volume_name,:system_architecture=>system_architecture,:track_count=>track_count,:sector_length=>sector_length})
      create_volume_response_msg=send_request_and_get_response(create_volume_request_msg)
      assert_equal(TNDP::CreateVolumeResponseMessage::OPCODE,create_volume_response_msg.opcode,"init volume response message should have correct opcode")
      assert_equal(system_architecture,create_volume_response_msg.system_architecture)      
      assert(File.exist?(image_full_path),"file just created should exist at #{image_full_path}")
      sector_data=([system_architecture.to_s,volume_name,track_count,sector_length].pack("Z12Z30CC")*200)[0,sector_length]
      track_no=track_count-1
      sector_no=1
      sector_write_request_msg=TNDP::SectorWriteRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name,:sector_data=>sector_data})
      sector_write_response_msg=send_request_and_get_response(sector_write_request_msg)
      assert_equal(TNDP::SectorWriteResponseMessage::OPCODE,sector_write_response_msg.opcode,"sector write response message should have correct opcode")

      file_system_image=RipXplore.best_fit_from_filename(image_full_path)
      assert_equal(track_count,file_system_image.track_count,"file just created should have correct number of tracks")
      assert_equal(sector_data,file_system_image.get_sector(track_no,sector_no),"file just created should have sector data set correctly")
      
 end
 raise "done"
    #test every combination of host and file system
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
        entry_count=0
        volume_catalog_response_msg.catalog_entries.each do |entry|
          assert_equal(desired_system_architecture,entry[1],"each entry should be for specified architecture") unless desired_system_architecture==:any
          assert_equal(desired_file_system,entry[2],"each entry should be for specified file system") unless desired_file_system==:any
          volume_name=entry[0]          
          track_no=entry[3]-1 #last track
          sector_no=1
          sector_length=entry[4]
          if entry_count==0 then  #do these tests only once for each combination of architecture/file system
            assert_equal(TNDP::ErrorCodes::INVALID_VOLUME_NAME,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>"invalid file name"})).errorcode,"invalid volume name should return error")
            assert_equal(TNDP::ErrorCodes::INVALID_TRACK_NUMBER,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>0xDEAD,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name})).errorcode,"invalid track number should return error")
            assert_equal(TNDP::ErrorCodes::INVALID_SECTOR_NUMBER,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>0xBEEF,:sector_length=>sector_length,:volume_name=>volume_name})).errorcode,"invalid sector number should return error")
            assert_equal(TNDP::ErrorCodes::INVALID_SECTOR_LENGTH,send_request_and_get_response(TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>0xD00D,:volume_name=>volume_name})).errorcode,"invalid sector length should return error")
          end
          file_system_image=RipXplore.best_fit_from_filename("#{TEST_IMAGES_DIR}/#{volume_name}")
          assert_equal(sector_length,file_system_image.get_sector(track_no,sector_no).length,"sector as read from disk should be of correct length")      
          sector_read_request_msg=TNDP::SectorReadRequestMessage.new({:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name})
          sector_read_response_msg=send_request_and_get_response(sector_read_request_msg)                    
          
          assert(sector_read_response_msg.respond_to?(:sector_data),"sector read response message should include sector data")  
          assert_equal(sector_length,sector_read_response_msg.sector_data.length,"sector read response message should include full length sector")
          assert_equal(TNDP.hex_dump(file_system_image.get_sector(track_no,sector_no)),TNDP.hex_dump(sector_read_response_msg.sector_data),"data returned from server should match data read directly from disk")
          entry_count+=1
        end
        catalog_offset+=volume_catalog_response_msg.catalog_entries.length
        done=(catalog_offset>volume_catalog_response_msg.total_catalog_size-1)
      end    
    end
    server.shutdown
  end

end