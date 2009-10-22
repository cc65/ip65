unpatched_applewin_filename='unpatched_applewin.exe'
patched_applewin_filename='applewin.exe'

c700_rom_filename='c700_rom.bin'
bankswitch_eeprom_filename="bankswitch_eeprom.bin"

[unpatched_applewin_filename,c700_rom_filename,bankswitch_eeprom_filename].each do |filename|
   if !(FileTest.file?(filename)) then
     puts "file '#{filename}' not found"
     exit
  end

end

filebytes=File.open(unpatched_applewin_filename,"rb").read

c700_sig=(07).chr*256
bankswitch_eeprom_sig=(0xF0).chr*256

c700_rom_offset=filebytes.index(c700_sig) 
raise "C700 ROM signature not found in #{unpatched_applewin_filename}" if c700_rom_offset.nil?
bankswitch_eeprom_offset=filebytes.index(bankswitch_eeprom_sig) 
raise "bankswitch EEPROM signature not found in #{unpatched_applewin_filename}" if bankswitch_eeprom_offset.nil?

c700_rom=File.open(c700_rom_filename,"rb").read
bankswitch_eeprom=File.open(bankswitch_eeprom_filename,"rb").read

filebytes[c700_rom_offset,c700_rom.length]=c700_rom
filebytes[bankswitch_eeprom_offset,bankswitch_eeprom.length]=bankswitch_eeprom
filehandle=File.open(patched_applewin_filename,"wb")
filehandle<<filebytes
filehandle.close


#-- LICENSE FOR patch_applewin.rb --
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
