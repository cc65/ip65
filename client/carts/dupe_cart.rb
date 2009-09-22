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