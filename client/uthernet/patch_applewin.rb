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