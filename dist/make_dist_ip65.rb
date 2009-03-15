gem 'archive-zip' 
require 'archive/zip'
require 'ftools'

WORKING_DIR=File.expand_path(File.dirname(__FILE__)+"/ip65")
SRC_DIR=File.expand_path(File.dirname(__FILE__)+"/../")
["","ip65","doc","cfg","drivers","inc","test","clients"].each do |dir_suffix|
  dir_path="#{WORKING_DIR}/#{dir_suffix}"
  Dir.mkdir(dir_path) unless File.exist?(dir_path)
end

[
  ["client/ip65/*.[s|i]","ip65/"],
  ["client/ip65/Makefile","ip65/"],
  ["client/inc/*.i","inc/"],
  ["client/test/*.[s|i]","test/"],
  ["client/test/Makefile","test/"],
  ["client/drivers/*.[s|i]","drivers/"],
  ["client/drivers/Makefile","drivers/"],
  ["client/cfg/*","cfg/"],
   ["doc/ip65.html","doc/"],
  ["client/Makefile","/"],  
].each do |args|
  dest="#{WORKING_DIR}/#{args[1]}"
  Dir["#{SRC_DIR}/#{args[0]}"].each do |src|
    File.copy(src,dest)
    puts "#{src}->#{dest}"
  end  
end

dummy_makefile=File.new("#{WORKING_DIR}/clients/Makefile","w")
dummy_makefile<<"#dummy makefile, so we can reuse the top level Makefile from the netboot65/clients directory\nall:\n"
dummy_makefile.close

zipfile_name=File.dirname(__FILE__)+"/ip65-#{Time.now.strftime("%Y-%m-%d")}.zip"
Archive::Zip.archive(zipfile_name, WORKING_DIR)

