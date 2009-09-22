#
# Vice will treat a cartridge bin file that is of an even length as if the first 2 bytes in the file are a load address to be skipped over
# so we want to make sure the bin file is an odd length - specifically 8193 bytes
#


PAD_BYTE=0xff.chr
filename=ARGV[0]

if filename.nil? then
  puts "no filename specified"
  exit
end

if ARGV[1].nil? then
  puts "no padding length specified"
  exit
end
file_length=ARGV[1].to_i

infile=File.open(filename,"rb").read
puts "fixing length of #{filename} from #{infile.length} to #{file_length} bytes"  
outfile=File.open(filename,"wb")
outfile<<infile
outfile<<PAD_BYTE*(file_length-infile.length)
outfile.close