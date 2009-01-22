#
# message formats for Trivial Network Disk Protocol
#
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'SubclassTracking'


#useful extension to Hash class

class Hash
  def key_by_value(value)
    self.keys.each do |key|
      return key if self[key]==value
    end
    nil
  end
end

module TNDP

  OPCODES={
    0x00 =>"CAPABILITIES REQUEST",
		0x01 =>"VOLUME CATALOG REQUEST",
		0x02 =>"READ SECTOR REQUEST",
		0x03 =>"WRITE SECTOR REQUEST",
    0x80 =>"CAPABILITIES RESPONSE",
		0x81 =>"VOLUME CATALOG RESPONSE",
		0x82 =>"READ SECTOR RESPONSE",
		0x83 =>"WRITE SECTOR RESPONSE",
		0xFF =>"ERROR RESPONSE",
  }
  
  SYSTEM_ARCHITECTURES={
    :any=>0x00,
    :c64=>0x64,
    :apple2=>0xA2,
    :other=>0xFF,
  }

FILESYSTEMS={
  :any=>0x00,
  :raw=>0x01,
  :apple_dos_33=>0x02,
  :prodos=>0x03,
  :cpm=>0x04,
  :cbm_dos=>0x05
}
  
  class ErrorCodes
    OK=0x00
    UNKNOWN_OPCODE=0x02
    VERSION_NOT_SUPPORTED=0x03
    ARCHITECTURE_NOT_SUPPORTED=0x04
    FILESYSTEM_NOT_SUPPORTED=0x05
    INVALID_VOLUME_NAME=0x06
    INVALID_TRACK_NUMBER=0x07
    INVALID_SECTOR_NUMBER=0x08
    INVALID_SECTOR_LENGTH=0x09
    INTERNAL_SERVER_ERROR=0xFF
  end

  class FormatError <RuntimeError
  end
  
  class BufferTooShort < FormatError
  end
  
  class InvalidSignature < FormatError
  end
  
  class InvalidVersion < FormatError
  end
  
  class InvalidOpcode < FormatError
  end
  
  def TNDP.coalesce(a,b)
    if a.nil? then 
      b
    else
      a
    end
  end

  @@next_transaction_id=0
  def TNDP.next_transaction_id
    @@next_transaction_id+=1
    @@next_transaction_id
  end

  MESSAGE_SIGNATURE='TNDP'
  VERSION_ID=1
  def TNDP.message_from_buffer(buffer)
    raise BufferTooShort unless buffer.length>=0x07
    signature,version_id,transaction_id,opcode=buffer.unpack("Z4CnC")
    raise InvalidSignature unless signature==MESSAGE_SIGNATURE
    raise InvalidVersion unless version_id==1
 
    BaseMessage.subclasses.each do |msg_type|
      next unless defined?(msg_type::OPCODE)
      return msg_type.from_buffer(buffer) if opcode==msg_type::OPCODE
    end    
    raise InvalidOpcode
  end  
  
  class BaseMessage
    attr_accessor :signature,:version_id,:transaction_id,:opcode,:raw_bytes
    
    def raw_bytes
      @raw_bytes=to_buffer if @raw_bytes.nil?
      @raw_bytes
    end
    
    def to_buffer 
      packed_buffer=[signature,version_id,transaction_id,opcode].pack("Z4cnC")
      packed_buffer
    end
    
    def to_s
      hex_dump+ 
"
TNDP MESSAGE
SIGNATURE:      #{signature}
VERSION:        #{version_id}
TRANSACTION ID: 0x#{"%04x"%transaction_id}
OPCODE:         0x#{"%02X"%opcode} [#{OPCODES[opcode].nil? ? "UNKNOWN" : OPCODES[opcode]}]"
    end
    
    def hex_dump
      buffer=raw_bytes
      s=""
      (0..(buffer.length/16)).each {|line_number|
         lhs=""
         rhs=""
         start_byte=line_number*16
         line=buffer[start_byte,16]
        if line.length>0 then
           line.each_byte {|byte|
              lhs+= sprintf("%02X ", byte)
              rhs+=byte.chr.sub(/[\x00-\x1f]/,'.')
          }
          lhs+=" "*(16-line.length)*3
          s+=sprintf("%02X\t%s %s\n",start_byte,lhs,rhs)
        end
      }
      s
    end
    
    def initialize(args={}) 
  #    puts "args:"
  #    args.keys.each do |key|
  #      puts "#{key}: #{args[key]}\n"
  #    end
      @signature=TNDP.coalesce(args[:signature],MESSAGE_SIGNATURE)
      @version_id=TNDP.coalesce(args[:version_id],0x01)
      @transaction_id=TNDP.coalesce(args[:transaction_id],TNDP.next_transaction_id)
      @opcode=TNDP.coalesce(args[:opcode],0xFF)      
    end
    
private    
    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode=buffer.unpack("Z4CnC")  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,:opcode=>opcode})
    end

  self.extend SubclassTracking

  end

  class RequestMessage < BaseMessage
    attr_reader :opcode
  end
  
  class ResponseMessage < BaseMessage
  end
  
  class CapabilitiesRequestMessage < BaseMessage
    OPCODE=0x00
    def initialize(args={})
      args[:opcode]=OPCODE
      super(args)
    end
  end

  class CapabilitiesResponseMessage < BaseMessage
    OPCODE=0x80
    attr_reader :application_name,:highest_supported_version_id,:supported_architectures
    def initialize(args={})
      args[:opcode]=OPCODE
      @application_name=TNDP.coalesce(args[:application_name],"netboot 65")
      @highest_supported_version_id=TNDP.coalesce(args[:highest_supported_version_id],VERSION_ID)
      @supported_architectures=TNDP.coalesce(args[:supported_architectures],[[TNDP::SYSTEM_ARCHITECTURES[:any],0]])      
      super(args)
    end
    
    def to_s
      s=""
      supported_architectures.each do |sfs|
        system_architecture_id=sfs[0]
        system_architecture_name=TNDP.coalesce(TNDP::SYSTEM_ARCHITECTURES.key_by_value(system_architecture_id),:unknown)
        count=sfs[1]
        s<<"\n%s [0x%02X] - 0x%04X" % [system_architecture_name,system_architecture_id,count]
      end
      super+s
    end
    
    def to_buffer
      supported_architectures_buffer=[supported_architectures.length].pack("C")
      supported_architectures.each{|a| supported_architectures_buffer+=a.pack("CC")}
      super+[highest_supported_version_id,application_name].pack("CZ20")+supported_architectures_buffer
    end
    
    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,highest_supported_version_id,application_name,supported_architectures_length=buffer.unpack("Z4CnCCZ20C")      
      supported_architectures={}
      supported_architectures_length.times do |i|
        system_architecture_id=buffer[(i*2)+0x1E]
        count=buffer[(i*2)+0x1F]
        supported_architectures[system_architecture_id]=count
      end  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:application_name=>application_name,:highest_supported_version_id=>highest_supported_version_id,:supported_architectures=>supported_architectures})
    end

  end

  class VolumeCatalogRequestMessage < BaseMessage
    OPCODE=0x01
    def initialize(args={})
      args[:opcode]=OPCODE
      super(args)
    end
  end

  class VolumeCatalogResponseMessage < BaseMessage
    OPCODE=0x81
    def initialize(args={})
      args[:opcode]=OPCODE
      super(args)
    end
  end

  class ErrorResponseMessage < BaseMessage
    OPCODE=0xFF
    attr_reader :errorcode,:error_description,:original_data_elements
    def initialize(args={})
      args[:opcode]=OPCODE
      @errorcode=TNDP.coalesce(args[:errorcode],0xFF)
      @error_description=TNDP.coalesce(args[:error_description],"an error occured")
      @original_data_elements=TNDP.coalesce(args[:original_data_elements],"")
      super(args)
    end
    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,errorcode,error_description,original_data_elements=buffer.unpack("Z4CnCnZ64Z16")  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:errorcode=>errorcode,:error_description=>error_description,:original_data_elements=>original_data_elements})
    end
    
    def to_s
        super+"  
ERROR CODE:     0x#{"%02X"%errorcode}
DESCRIPTION:    #{error_description}
ORIGINAL DATA:  #{original_data_elements}
" 
    end      
    def to_buffer
      super+[errorcode,error_description,0,original_data_elements].pack("nZ63CZ16")
    end
    
   def self.create_error_response(original_request_buffer,errorcode,error_description)
     transaction_id=original_request_buffer[5,2].unpack("n")[0] #pull direct from data in case "message_from_buffer" was what raised the error 
     self.new({:signature=>MESSAGE_SIGNATURE,:version=>VERSION_ID,:transaction_id=>transaction_id,
      :opcode=>OPCODE,:errorcode=>errorcode,:error_description=>error_description,:original_data_elements=>original_request_buffer[0,16]})
    end
  end
end
