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
#-- LICENSE FOR fix_cart.rb --
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations
# under the License.
# 
# The Original Code is netboot65.
# 
# The Initial Developer of the Original Code is Jonno Downes,
# jonno@jamtronix.com.
# Portions created by the Initial Developer are Copyright (C) 2009
# Jonno Downes. All Rights Reserved.  
# -- LICENSE END --
