$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

def log_msg(msg)
  puts msg
end

Dir.glob("tc_*.rb").each do |tc|
  require tc
end