
$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

gem 'archive-zip' 
require 'archive/zip'
require 'ftools'

WORKING_DIR=File.expand_path(File.dirname(__FILE__)+"/ip65")
SRC_DIR=File.expand_path(File.dirname(__FILE__)+"/../")
["","ip65","doc","cfg","drivers","inc","test","carts"].each do |dir_suffix|
  dir_path="#{WORKING_DIR}/#{dir_suffix}"
  Dir.mkdir(dir_path) unless File.exist?(dir_path)
end

[
  ["client/ip65/*.[s|i]","ip65/"],
  ["client/ip65/Makefile","ip65/"],
  ["client/carts/*.[s|i]","carts/"],
  ["client/carts/Makefile","carts/"],
  ["client/carts/*.rb","carts/"],
  ["client/carts/*.obj","carts/"],
  ["client/carts/*.src","carts/"],
  ["client/inc/*.i","inc/"],
  ["client/inc/vt100_font.bin","inc/"],
  ["client/test/*.[s|i]","test/"],
  ["client/test/Makefile","test/"],
  ["client/drivers/*.[s|i]","drivers/"],
  ["client/drivers/Makefile","drivers/"],
  ["client/cfg/*","cfg/"],
   ["doc/ip65.html","doc/index.html"],
   ["doc/ca65-doc*.*","doc/"],
  ["doc/CONTRIBUTORS.txt","doc/"],
  ["doc/LICENSE.txt","doc/"],
  ["client/Makefile","/"],  
].each do |args|
  dest="#{WORKING_DIR}/#{args[1]}"
  Dir["#{SRC_DIR}/#{args[0]}"].each do |src|
    File.copy(src,dest)
    puts "#{src}->#{dest}"
  end  
end

#dummy_makefile=File.new("#{WORKING_DIR}/carts/Makefile","w")
#dummy_makefile<<"#dummy makefile, so we can reuse the top level Makefile from the netboot65/client directory\nall:\n"
#dummy_makefile.close

require 'document_ca65_source_as_html.rb'
codebase_dir=WORKING_DIR
output_dir="#{WORKING_DIR}/doc"
codebase_title='ip65'
document_ca65_source_as_html(codebase_dir,codebase_title,output_dir)
zipfile_name=File.dirname(__FILE__)+"/ip65-#{Time.now.strftime("%Y-%m-%d")}.zip"
Archive::Zip.archive(zipfile_name, WORKING_DIR)
