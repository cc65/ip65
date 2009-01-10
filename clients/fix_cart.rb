#
# Vice will treat a cartridge bin file that is of an even length as if the first 2 bytes in the file are a load address to be skipped over
# so we want to make sure the bin file is an odd length - specifically 8193 bytes
#

FILE_LENGTH=8193
PAD_BYTE=0xff.chr
filename=ARGV[0]
if filename.nil? then
  puts "no filename specified"
  exit
end
  
puts "fixing length of #{filename} to #{FILE_LENGTH} bytes"  
infile=File.open(filename,"rb").read
outfile=File.open(filename,"wb")
outfile<<infile
outfile<<PAD_BYTE*(FILE_LENGTH-infile.length)
outfile.close