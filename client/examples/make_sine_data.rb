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


#-- LICENSE FOR make_sine_data.rb --
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
# The Original Code is ip65.
# 
# The Initial Developer of the Original Code is Jonno Downes,
# jonno@jamtronix.com.
# Portions created by the Initial Developer are Copyright (C) 2009
# Jonno Downes. All Rights Reserved.  
# -- LICENSE END --
