# a q&d hack for tftping down a file and dumping it to std-out
# useful for testing the netboot65 tftp server, especially the hacks for directory listings


require 'net/tftp'

def usage
  @progname=File.basename($0)
  puts "usage: #{@progname} <servername> <filename>"
  puts "specified filename will be downloaded from specified tftp server and dumpt to stdout"
  true
end 
 
number_of_options=ARGV.length
usage && exit unless number_of_options==2
servername=ARGV[0]
filename=ARGV[1] 

t = Net::TFTP.new(servername)
t.getbinary(filename,$stdout)

