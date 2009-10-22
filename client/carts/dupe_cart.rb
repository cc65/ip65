infilename=ARGV[0]
outfilename=ARGV[1]
duplication=ARGV[2].to_i

if duplication.nil? then
  puts "usage: dupe_cart.rb [input filename] [output filename] [number of duplications]"
  exit
end


infile=File.open(infilename,"rb").read
puts "copying #{infilename} to #{outfilename} #{duplication} times"  
outfile=File.open(outfilename,"wb")
duplication.times {outfile<<infile}
outfile.close
#-- LICENSE FOR dupe_cart.rb --
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
