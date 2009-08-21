errors="<table><tr><th>ERROR CODE</th><th>DESCRIPTION</th></tr>\n"
IO.readlines("netboot65/inc/nb65_constants.i").each do |line|
	if line=~/NB65_ERROR_(\S*).*(\$\S\S)/ then
	code=$2
	description=$1.gsub("_"," ")
	errors<<"<tr><td>#{code}</td><td>#{description}</td></tr>\n"
	end
end
errors<<"</table>\n"
puts errors

