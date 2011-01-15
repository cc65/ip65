
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'RubyGems'
require 'archive/zip'
require 'ftools'

WORKING_DIR=File.expand_path(File.dirname(__FILE__)+"/netboot65")
SRC_DIR=File.expand_path(File.dirname(__FILE__)+"/../")
VERSION_FILE=File.expand_path(File.dirname(__FILE__)+"/version_number.txt")
VERSION_INC_FILE=File.expand_path(File.dirname(__FILE__)+"/../client/inc/version.i")
version_string=File.open(VERSION_FILE).read

["","c64","lib","bin","boot","doc","inc"].each do |dir_suffix|
  dir_path="#{WORKING_DIR}/#{dir_suffix}"
  Dir.mkdir(dir_path) unless File.exist?(dir_path)
end

[
#["client/nb65/utherboot.dsk","a2/"],
["client/carts/set_ip_config.rb","bin/"],
#["client/nb65/nb65_rrnet.bin","c64/"],
["client/carts/kipperkart.prg","c64/"],
["client/carts/kipperkart.bin","c64/"],
["client/carts/kipperkart_rr.bin","c64/"],
["client/carts/kipperterm.bin","c64/"],
["client/carts/kipperterm_rr.bin","c64/"],
["client/carts/kipperterm.prg","c64/"],
["client/carts/kippergo.bin","c64/"],
["client/carts/kippergo_rr.bin","c64/"],
["client/carts/kippergo.prg","c64/"],
["client/carts/netboot.bin","c64/"],
#["client/nb65/d64_upload.prg","boot/"],
["client/examples/upnatom.prg","boot/"],
["server/lib/tftp_server.rb","lib"],
["server/lib/file_list.rb","lib"],
["server/bin/tftp_only_server.rb","bin/tftp_server.rb"],
#["server/bin/import_ags_games.rb","bin"],
#["server/boot/BOOTA2.PG2","boot"],
#["doc/README.Apple2.html","a2"],
["doc/README.C64.html","c64"],
["doc/netboot65.html","doc/index.html"],
#["doc/README.Apple2.html","doc"],
["doc/README.C64.html","doc"],
["doc/CONTRIBUTORS.txt","doc/"],
["doc/LICENSE.txt","doc/"],
["doc/CHANGES.txt","doc/"],
["doc/kipper_api_technical_reference.doc","doc"],
["client/inc/common.i","inc"],
["client/inc/kipper_constants.i","inc"],
["client/examples/upnatom.d64","c64/"],
#["client/nb65/d64_upload.s","examples/"],
#["client/nb65/nb65_skeleton.s","examples/"],
].each do |args|
  dest="#{WORKING_DIR}/#{args[1]}"
  Dir["#{SRC_DIR}/#{args[0]}"].each do |src|
    File.copy(src,dest)
    puts "#{src}->#{dest}"
  end  
end


zipfile_name=File.dirname(__FILE__)+"/netboot65-#{version_string}.zip"
Archive::Zip.archive(zipfile_name, WORKING_DIR)

(maj,min,rel)=version_string.split(".")
version_string="#{maj}.#{min}.#{(rel.to_i)+1}"

file=File.new(VERSION_INC_FILE,"w")
file<<".byte \"#{version_string}\"\n"
file.close

file=File.new(VERSION_FILE,"w")
file<<version_string
file.close
