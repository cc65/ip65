lib_path=File.expand_path(File.dirname(__FILE__)+"//..//lib")
$:.unshift(lib_path) unless $:.include?(lib_path)

require 'test/unit'
require 'tndp_server'

def log(msg)
  puts msg
end
class TestServer <Test::Unit::TestCase

  @@client_socket=UDPSocket.open()
  @@client_socket.connect("localhost",TNDPServer::LISTENING_PORT)
  
  
  def send_request_and_get_response(request)
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
    server=TNDPServer.new(File.dirname(__FILE__)+"/test_images")
    server.start
    capabilities_response_msg=send_request_and_get_response(TNDP::CapabilitiesRequestMessage.new())
    assert(capabilities_response_msg.respond_to?(:supported_architectures),"capabilities response message should include list of architectures supported by server")
    
    volume_catalog_response_msg=send_request_and_get_response(TNDP::VolumeCatalogRequestMessage.new())
    assert(capabilities_response_msg.respond_to?(:supported_architectures),"capabilities response message should include list of architectures supported by server")
    
    server.shutdown
  end

end