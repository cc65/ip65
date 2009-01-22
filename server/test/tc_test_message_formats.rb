lib_path=File.expand_path(File.dirname(__FILE__)+"//..//lib")
$:.unshift(lib_path) unless $:.include?(lib_path)

require 'test/unit'
require 'tndp'

class TestMessageFormats <Test::Unit::TestCase

  def test_message_validation
    
    assert_raise TNDP::BufferTooShort do
      TNDP.message_from_buffer("1234")
    end
    
    assert_raise TNDP::InvalidSignature do
      TNDP.message_from_buffer("1234567")
    end

    assert_raise TNDP::InvalidVersion do
      TNDP.message_from_buffer("TNDP567")
    end

    
  end
	def test_message_round_trip
    
    [TNDP::CapabilitiesRequestMessage,TNDP::CapabilitiesResponseMessage,TNDP::ErrorResponseMessage,TNDP::VolumeCatalogRequestMessage,TNDP::VolumeCatalogRequestMessage].each do |msg_type|
      created_msg=msg_type.new()
      assert_equal(msg_type::OPCODE,created_msg.opcode,"opcode for #{msg_type} should be 0x#{"%02x" % msg_type::OPCODE}")      
      puts created_msg.to_s
      round_trip_msg=TNDP.message_from_buffer(created_msg.raw_bytes)
      
      assert_equal(created_msg.raw_bytes,round_trip_msg.raw_bytes,"raw bytes should round-trip for #{msg_type}")
      assert_equal(created_msg.to_s,round_trip_msg.to_s,"to_s should be same for round-tripped #{msg_type}")
      assert_equal(created_msg.class,round_trip_msg.class,"class should round-trip for #{msg_type}")

    end

	end

end