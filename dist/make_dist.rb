
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

gem 'archive-zip' 
require 'archive/zip'
require 'ftools'

WORKING_DIR=File.expand_path(File.dirname(__FILE__)+"/netboot65")
SRC_DIR=File.expand_path(File.dirname(__FILE__)+"/../")
["","client","lib","bin","boot","doc","inc","examples"].each do |dir_suffix|
  dir_path="#{WORKING_DIR}/#{dir_suffix}"
  Dir.mkdir(dir_path) unless File.exist?(dir_path)
end

[
["client/clients/utherboot.dsk","client/"],
["client/clients/rrnetboot.bin","client/"],
["server/lib/tftp_server.rb","lib"],
["server/bin/tftp_only_server.rb","bin/tftp_server.rb"],
["server/bin/import_ags_games.rb","bin"],
["server/boot/BOOTA2.PG2","boot"],
["doc/README.*.txt","doc"],
["doc/nb65_api_technical_reference.doc","doc"],
["client/inc/nb65_constants.i","inc"],
["client/examples/dasm_example.asm","examples/"],
].each do |args|
  dest="#{WORKING_DIR}/#{args[1]}"
  Dir["#{SRC_DIR}/#{args[0]}"].each do |src|
    File.copy(src,dest)
    puts "#{src}->#{dest}"
  end  
end


zipfile_name=File.dirname(__FILE__)+"/netboot65-#{Time.now.strftime("%Y-%m-%d")}.zip"
Archive::Zip.archive(zipfile_name, WORKING_DIR)
