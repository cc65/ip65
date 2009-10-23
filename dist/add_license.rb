require 'find'

COMMENT_CHAR={
    "asm"=>";",
     "s"=>";",
     "inc"=>";",
      "i"=>";",
     "rb"=>"#",
}



def add_license_to_file(filename,original_codebase,original_developer_name,original_developer_email)

filename=~/\.([^.]+$)/
short_filename=File.basename(filename)
comment_char=COMMENT_CHAR[$1]
comment_char="" if comment_char.nil?

dash_dash="--"
license_text="


#{comment_char}#{dash_dash} LICENSE FOR #{short_filename} --
#{comment_char} The contents of this file are subject to the Mozilla Public License
#{comment_char} Version 1.1 (the \"License\"); you may not use this file except in
#{comment_char} compliance with the License. You may obtain a copy of the License at
#{comment_char} http://www.mozilla.org/MPL/
#{comment_char} 
#{comment_char} Software distributed under the License is distributed on an \"AS IS\"
#{comment_char} basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#{comment_char} License for the specific language governing rights and limitations
#{comment_char} under the License.
#{comment_char} 
#{comment_char} The Original Code is #{original_codebase}.
#{comment_char} 
#{comment_char} The Initial Developer of the Original Code is #{original_developer_name},
#{comment_char} #{original_developer_email}.
#{comment_char} Portions created by the Initial Developer are Copyright (C) #{Time.now.year}
#{comment_char} #{original_developer_name}. All Rights Reserved.  
#{comment_char} #{dash_dash} LICENSE END --
"

lines=File.new(filename).read
  if (lines=~/-- LICENSE FOR #{short_filename} #{dash_dash}/) then
    puts "skipping #{filename}"
    return
  end
  puts "#{filename} - #{lines.length} lines"
  f=File.new(filename,"w")
  f<<lines
  f<<license_text
  f.close
end


def add_license_to_files_in_dir(dirname,original_codebase,original_developer_name,original_developer_email)
  source_files=[]
  Find.find(dirname) do |path|
    Find.prune if path[0]=='.'
    path=~/\.([^.]+$)/
    source_files<<path unless COMMENT_CHAR[$1].nil?
  end
  source_files.each do |filename|
    add_license_to_file(filename,original_codebase,original_developer_name,original_developer_email)
  end
end


[
].each do |file|
  add_license_to_file(file,"ip65","Per Olofsson", "MagerValp@gmail.com")
end


add_license_to_files_in_dir(".","netboot65","Jonno Downes", "jonno@jamtronix.com")

 #~ number_of_options=ARGV.length
 #~ usage && exit unless number_of_options>=3
 #~ usage && exit unless (number_of_options%2) ==1 #must be an odd number of options
 #~ filename=ARGV[0]
 #~ if !(FileTest.file?(filename)) then
   #~ puts "file '#{filename}' not found"
   #~ exit
#~ end






#~ files_to_parse=[]
#~ Find.find(codebase_dir) do |path|
  #~ Find.prune if path[0]=='.'
  #~ files_to_parse  <<path.sub(codebase_dir,"").sub(/^\//,"") if path=~/\.s$/
#~ end
#~ files_to_parse.each do |filename|	
