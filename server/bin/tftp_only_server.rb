#
# tftp only server
#
# Jonno Downes (jonno@jamtronix.com) - January, 2009
# 
#

Thread.abort_on_exception=true

def log_msg(msg)
  puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{msg}"
end

lib_path=File.expand_path(File.dirname(__FILE__)+'/../lib')
$:.unshift(lib_path) unless $:.include?(lib_path)
require 'tftp_server'

bootfile_dir=File.expand_path(File.dirname(__FILE__)+'/../boot')
tftp_server_69=Netboot65TFTPServer.new(bootfile_dir,69)
tftp_server_69.start
#tftp_server_6502=Netboot65TFTPServer.new(bootfile_dir,6502)
#tftp_server_6502.start

begin
  loop do
    sleep(1)  #wake up every second to get keyboard input, so we break on ^C
  end
rescue Interrupt
  log_msg "got interrupt signal - shutting down"
end
tftp_server.shutdown
#tftp_server_6502.shutdown
log_msg "shut down complete."
