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

  MAX_CATALOG_ENTRIES_PER_MESSAGE=8
  MAX_VOLUME_NAME_LENGTH=57
  SYSTEM_ARCHITECTURES={
    :any=>0x00,
    :c64=>0x64,
    :apple2=>0xA2,
    :unknown=>0xFF,
  }

FILESYSTEMS={
  :any=>0x00,
  :raw=>0x01,
  :apple_dos_33=>0x02,
  :prodos=>0x03,
  :cpm=>0x04,
  :cbm_dos=>0x05,
  :unknown=>0xFF,
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

  def TNDP.hex_dump(buffer)
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
TRANSACTION ID: $#{"%04x"%transaction_id}
OPCODE:         $#{"%02X"%opcode} [#{OPCODES[opcode].nil? ? "UNKNOWN" : OPCODES[opcode]}]"
    end
    
    def hex_dump
      TNDP.hex_dump(raw_bytes)
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
      @supported_architectures=TNDP.coalesce(args[:supported_architectures],[[:any,0]])      
      super(args)
    end
    
    def to_s
      s=""
      supported_architectures.each do |entry|
        system_architecture_id=TNDP::SYSTEM_ARCHITECTURES[entry[0]]
        count=entry[1]
        s<<"\n%s [0x%02X] - 0x%04X" % [entry[0],system_architecture_id,count]
      end
      super+s
    end
    
    def to_buffer
      supported_architectures_buffer=[supported_architectures.length].pack("C")
      supported_architectures.each{|a| supported_architectures_buffer+=[TNDP::SYSTEM_ARCHITECTURES[a[0]],a[1]].pack("CC")}
      super+[highest_supported_version_id,application_name].pack("CZ20")+supported_architectures_buffer
    end
    
    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,highest_supported_version_id,application_name,supported_architectures_length=buffer.unpack("Z4CnCCZ20C")      
      supported_architectures={}
      supported_architectures_length.times do |i|
        system_architecture_id=buffer[(i*2)+0x1E]
        system_architecture=TNDP.coalesce(TNDP::SYSTEM_ARCHITECTURES.key_by_value(system_architecture_id),:unknown)
        count=buffer[(i*2)+0x1F]
        supported_architectures[system_architecture]=count
      end  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:application_name=>application_name,:highest_supported_version_id=>highest_supported_version_id,:supported_architectures=>supported_architectures})
    end

  end

  class VolumeCatalogRequestMessage < BaseMessage
    attr_reader :system_architecture, :file_system, :catalog_offset
    OPCODE=0x01
    def initialize(args={})
      args[:opcode]=OPCODE
      @system_architecture=TNDP.coalesce(TNDP::SYSTEM_ARCHITECTURES.key_by_value(TNDP::SYSTEM_ARCHITECTURES[args[:system_architecture]]),:any)
      @file_system=TNDP.coalesce(TNDP::FILESYSTEMS.key_by_value(TNDP::FILESYSTEMS[args[:file_system]]),:any)
      @catalog_offset=TNDP.coalesce(args[:catalog_offset],0)      
      super(args)
    end
    
    def to_s
      system_architecture_id=TNDP::SYSTEM_ARCHITECTURES[system_architecture]
      file_system_id=TNDP::FILESYSTEMS[file_system]
              super+"  
ARCHITECTURE:   #{system_architecture} [$#{"%02X"%system_architecture_id}]
FILE SYSTEM:    #{file_system} [$#{"%02X"%file_system_id}]
CATALOG OFFSET: $#{"%04x" % catalog_offset}"

    end
 
    def to_buffer
      super+[TNDP::SYSTEM_ARCHITECTURES[system_architecture],TNDP::FILESYSTEMS[file_system],catalog_offset].pack("CCn")      
    end
    
    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,system_architecture_id,file_system_id,catalog_offset=buffer.unpack("Z4CnCCCn")  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:system_architecture=>TNDP::SYSTEM_ARCHITECTURES.key_by_value(system_architecture_id),:file_system=>TNDP::FILESYSTEMS.key_by_value(file_system_id),:catalog_offset=>catalog_offset})
    end

  end

  class VolumeCatalogResponseMessage < BaseMessage
    attr_reader :catalog_offset,:total_catalog_size,:catalog_entries
    OPCODE=0x81
    def initialize(args={})
      args[:opcode]=OPCODE
      @catalog_entries=TNDP.coalesce(args[:catalog_entries],[])
      @catalog_offset=TNDP.coalesce(args[:catalog_offset],0)
      @total_catalog_size=TNDP.coalesce(args[:total_catalog_size],0)
      super(args)
    end
    def to_s
            s="\nCATALOG ENTRIES:\n___________________"
      catalog_entries.each do |entry|
        s<<"\nVOLUME NAME: %s\n\tSYSTEM ARCHITECTURE: %s\n\tFILE SYSTEM: %s\n\tTRACKS : 0x%04X\n\tSECTOR SIZE: 0x%04X" % entry 
      end
      super+"
      CATALOG SIZE:   $#{"%04x" % total_catalog_size}
      CATALOG OFFSET: $#{"%04x" % catalog_offset}"+s
    end
    
    def to_buffer
      catalog_buffer=[total_catalog_size,catalog_offset,catalog_entries.length].pack("nnC")
      catalog_entries.each do |entry| 
        catalog_buffer+=[entry[0][0,TNDP::MAX_VOLUME_NAME_LENGTH],TNDP::SYSTEM_ARCHITECTURES[entry[1]],TNDP::FILESYSTEMS[entry[2]],entry[3],entry[4]].pack("Z#{TNDP::MAX_VOLUME_NAME_LENGTH+1}CCnn")
      end
      super+catalog_buffer
    end

    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,total_catalog_size,catalog_offset,catalog_entries_length=buffer.unpack("Z4CnCnnC")      
      catalog_entries=[]
      catalog_entries_length.times do |i|
        entry_buffer=buffer[0x0D+(i*(TNDP::MAX_VOLUME_NAME_LENGTH+7)),TNDP::MAX_VOLUME_NAME_LENGTH+7]
        volume_name,system_architecture_id,file_system_id,track_count,sector_size=entry_buffer.unpack("Z#{TNDP::MAX_VOLUME_NAME_LENGTH+1}CCnn")
        system_architecture=TNDP.coalesce(TNDP::SYSTEM_ARCHITECTURES.key_by_value(system_architecture_id),:unknown)
        file_system=TNDP.coalesce(TNDP::FILESYSTEMS.key_by_value(file_system_id),:unknown)
        catalog_entries<<[volume_name,system_architecture,file_system,track_count,sector_size]
      end  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:total_catalog_size=>total_catalog_size,:catalog_offset=>catalog_offset,:catalog_entries=>catalog_entries})
    end
  end

  class SectorReadRequestMessage < BaseMessage
    attr_reader :track_no,:sector_no,:sector_length,:volume_name
    OPCODE=0x02
    def initialize(args={})
      args[:opcode]=OPCODE
      [:track_no,:sector_no,:sector_length,:volume_name].each do |arg|
        raise "#{arg} must be specified in a #{self.class}" if args[arg].nil?
      end
      
      @track_no=args[:track_no]
      @sector_no=args[:sector_no]
      @sector_length=args[:sector_length]
      @volume_name=args[:volume_name]
      
      super(args)
    end
  
  def to_s
              super+"
VOLUME NAME:    #{volume_name}              
TRACK NO:       $#{"%04X"%track_no}
SECTOR NO:      $#{"%04X"%sector_no}
SECTOR LENGTH:  $#{"%04x" % sector_length}"
    end
   
    def to_buffer
      super+[track_no,sector_no,sector_length,volume_name[0,MAX_VOLUME_NAME_LENGTH]].pack("nnnZ#{TNDP::MAX_VOLUME_NAME_LENGTH+1}")
    end

    def self.from_buffer(buffer)
      signature,version_id,transaction_id,opcode,track_no,sector_no,sector_length,volume_name=buffer.unpack("Z4CnCnnnZ#{TNDP::MAX_VOLUME_NAME_LENGTH+1}")
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name})
    end
  end

  class SectorReadResponseMessage < SectorReadRequestMessage
    attr_reader :sector_data
    def initialize(args={})
      raise "sector_data must be specified in a #{self.class}" if args[:sector_data].nil?
      @sector_data=args[:sector_data]      
      super(args)
    end
    def to_s
      super+"\nSECTOR DATA:\n"+TNDP.hex_dump(sector_data)
    end
    
    def to_buffer
      super+sector_data.pack("C#{sector_length}")
    end
    
    def from_buffer
      signature,version_id,transaction_id,opcode,track_no,sector_no,sector_length,volume_name,sector_data=buffer.unpack("Z4CnCnnnZ#{TNDP::MAX_VOLUME_NAME_LENGTH+1}C*")
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:track_no=>track_no,:sector_no=>sector_no,:sector_length=>sector_length,:volume_name=>volume_name,:sector_data=>sector_data})
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
      signature,version_id,transaction_id,opcode,errorcode,error_description,original_data_elements=buffer.unpack("Z4CnCnZ128Z16")  
      self.new({:signature=>signature,:version=>version_id,:transaction_id=>transaction_id,
      :opcode=>opcode,:errorcode=>errorcode,:error_description=>error_description,:original_data_elements=>original_data_elements})
    end
    
    def to_s
        super+"  
ERROR CODE:     $#{"%02X"%errorcode}
DESCRIPTION:    #{error_description}
ORIGINAL DATA:  #{original_data_elements}
" 
    end      
    def to_buffer
      super+[errorcode,error_description,0,original_data_elements].pack("nZ127CZ16")
    end
    
   def self.create_error_response(original_request_buffer,errorcode,error_description)
     transaction_id=original_request_buffer[5,2].unpack("n")[0] #pull direct from data in case "message_from_buffer" was what raised the error 
     self.new({:signature=>MESSAGE_SIGNATURE,:version=>VERSION_ID,:transaction_id=>transaction_id,
      :opcode=>OPCODE,:errorcode=>errorcode,:error_description=>error_description,:original_data_elements=>original_request_buffer[0,16]})
    end
  end
end
