#
# Jonno Downes (jonno@jamtronix.com) - January, 2009
# 
#

require 'scanf'
ags_games_dir=ARGV[0]

if ags_games_dir.nil? or !(File.directory?(ags_games_dir)) then
  scriptname=File.basename(__FILE__)
  puts "usage: #{scriptname} <path to ags games directory>"
  exit
end

output_dir=File.expand_path(File.dirname(__FILE__)+"/../boot")
puts "importing games from #{ags_games_dir} to #{output_dir}"
Dir.chdir(ags_games_dir) do 
  Dir.glob("*#06*").each do |input_filename|
    if (input_filename=~/(.+)#06(\w\w\w\w)/) then
      base_filename=$1
      load_address=$2.scanf("%4x")[0]
      file_data=File.new(input_filename,"rb").read
      file_length=file_data.length
#      puts "#{input_filename} : #{base_filename},A$#{"%04X" % load_address},L$#{"%04X" % file_length}"
      header=[load_address,file_length].pack("vv")
      out_file=File.new("#{output_dir}/#{base_filename}.PG2","wb")
      out_file<<header
      out_file<<file_data
      out_file.close
    end
  end
end