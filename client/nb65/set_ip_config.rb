#cartridge offsets:
#	$18=MAC address (6 bytes)
#	$1E=IP address (4 bytes)
#	$22=netmask (4 bytes)
#	$26=gateway (4 bytes)
#	$2A=DNS (4 bytes)
#	$2E=TFTP server (4 bytes)


@cartridge_offsets={
#symobol => offset, length
  :mac=>[0x18,6],
  :ip=>[0x1e,4],
  :netmask=>[0x22,4],
  :gateway=>[0x26,4],
  :dns=>[0x2a,4],
  :tftp=>[0x2e,4],
 } 
 
 @progname=File.basename($0)
 def show_options
   puts  "valid options are: #{@cartridge_offsets.keys.join(", ")}"
   puts "mac auto will automagically generate a pseudorandom MAC"
end
 def usage 
  puts "#{@progname} <image> <option> <value> [<option> <value> ..]"
  puts "multiple options may be set"
  show_options
  true
 end 
 
 number_of_options=ARGV.length
 usage && exit unless number_of_options>=3
 usage && exit unless (number_of_options%2) ==1 #must be an odd number of options
 filename=ARGV[0]
 if !(FileTest.file?(filename)) then
   puts "file '#{filename}' not found"
   exit
end

 
 filebytes=File.open(filename,"rb").read

 if !(filebytes[0x09,4]=="NB65") then
   puts "file '#{filename}' does not appear to be a netboot65 cartridge image"
   exit
end

(number_of_options/2).times do |i|
  option=ARGV[i*2+1]
  value=ARGV[i*2+2]
#  puts "#{option} : #{value}"
  offsets=@cartridge_offsets[option.to_sym]
  if offsets.nil? then
    puts "invalid option #{option}"
    show_options
    exit
  end
  option_offset=offsets[0]
  option_length=offsets[1]
  
  if option_length==6 then
    if value.downcase=="auto" then
      require 'digest/md5'
      digest = Digest::MD5.digest(Time.now.to_s)
      mac=[0x00,0x80,0x10,digest[0],digest[1],Kernel.rand(255)]
    else
      split_values=value.split(":")
      if (split_values.length!=6) || (split_values[5].nil?) then
        puts "'#{value}' is not a valid MAC address. (e.g. 12:34:56:78:ab:cd)"
        exit
      end
      mac=[]
      6.times do |j|      
        mac[j]=split_values[j].hex
  #      puts "#{split_values[j]}->#{"%02X" % mac[j]}"
      end
    end
    packed_option=mac.pack("cccccc")
  else #it must be an IP
    split_values=value.split(".")
    if (split_values.length!=4) || (split_values[3].nil?) then
      puts "'#{value}' is not a valid IP format. (e.g. 192.168.1.64)"
      exit
    end
    ip=[]
    4.times do |j|      
      ip[j]=split_values[j].to_i
#      puts "#{split_values[j]}->#{ip[j]}"
      if (ip[j]<0) || (ip[j]>255) then
      puts "'#{value}' is not a valid IP format. (e.g. 192.168.1.64)"
      exit
    end

    end
    packed_option=ip.pack("cccc")
  end
  filebytes[option_offset,option_length]=packed_option
end

filehandle=File.open(filename,"wb")
filehandle<<filebytes
filehandle.close