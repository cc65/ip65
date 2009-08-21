f=File.open("sine_data.i","w")

TABLE_ENTRIES=0x80
AMPLITUDE=255
OFFSET=00

TABLE_ENTRIES.times do |i|
  value=OFFSET+Math.sin(Math::PI*i.to_f/TABLE_ENTRIES.to_f)*AMPLITUDE
  if i%0x08==0
    f<<"\n.byte " 
  else
    f<<", "
  end
  f<<"$%02x" % value
end

f.close