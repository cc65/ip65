def document_ca65_source_as_html(codebase_dir,codebase_title,output_dir)



Dir.mkdir(output_dir) unless File.exist?(output_dir)

symbol_attributes={}
html_filenames={}
file_overviews={}


puts "generating documentation for #{codebase_title}"

documentation_title="#{codebase_title} technical reference"
require 'find'

files_to_parse=[]
Find.find(codebase_dir) do |path|
  Find.prune if path[0]=='.'
  files_to_parse  <<path.sub(codebase_dir,"").sub(/^\//,"") if path=~/\.s$/
end
files_to_parse.each do |filename|	

  html_filename="#{filename.gsub(/[\/.]/,"_")}.html"
  puts "scanning #{filename} (#{html_filename})"
  html_filenames[filename]=html_filename
  last_comment=nil
  symbol=nil
  file_overviews[filename]=""
  found_non_comment_line=false
  full_filename="#{codebase_dir}/#{filename}"
	File.open(full_filename).each_line do |line|
    
    #skip to next line if this is nothing but white space
    next if line=~/^\s*$/
    
    last_symbol=symbol unless symbol.nil?
    symbol=nil
    if (line=~/^\s*;(.*)/) && !(found_non_comment_line) then
      file_overviews[filename]<<"#{$1}\n"
    else
      found_non_comment_line=true      
    end
    

		if line=~/\.export\s+(\w+)/ then
			symbol=$1
      symbol_attributes[symbol]={} if symbol_attributes[symbol].nil?
			symbol_attributes[symbol][:type]=:function
			symbol_attributes[symbol][:defined_in]=[] if symbol_attributes[symbol][:defined_in].nil?
      symbol_attributes[symbol][:defined_in]<<filename
      filename
		end

		if line=~/\.exportzp\s+(\w+)/ then
			symbol=$1
      symbol_attributes[symbol]={} if symbol_attributes[symbol].nil?
			symbol_attributes[symbol][:type]=:variable
      symbol_attributes[symbol][:zero_page]=true
			symbol_attributes[symbol][:defined_in]=[] if symbol_attributes[symbol][:defined_in].nil?
      symbol_attributes[symbol][:defined_in]<<filename
		end

		if line=~/(\w+):?.*\.res\s+(\S+)/ then
			symbol=$1
			size=$2
      if !symbol_attributes[symbol].nil? then
        symbol_attributes[symbol][:type]=:variable 
        symbol_attributes[symbol][:size]={} if symbol_attributes[symbol][:size].nil?
        symbol_attributes[symbol][:size][filename]=size
      end
		end

		if line=~/(\w*)(:)*\s*\.(byte|asciiz)\s+([^;]*)/ then
      symbol=$1      
      symbol=last_symbol if symbol.length<1
      value=$4
						
      if !symbol_attributes[symbol].nil? then
        symbol_attributes[symbol][:type]=:constant 
        symbol_attributes[symbol][:value]={} if symbol_attributes[symbol][:value].nil?
        if symbol_attributes[symbol][:value][filename].nil? then
          symbol_attributes[symbol][:value][filename]=value
        else
          symbol_attributes[symbol][:value][filename]+="\n#{value}"
        end
      end
		end


		if line=~/(\w+):?.*=/ then
			symbol=$1
        if !symbol_attributes[symbol].nil? then
        symbol_attributes[symbol][:type]=:variable if symbol_attributes[symbol][:type]==:function
      end
		end

		if line=~/(\w+).*=\s?([^;]*)/ then
			symbol=$1
			value=$2
      if !symbol_attributes[symbol].nil? then
        symbol_attributes[symbol][:type]=:constant 
        symbol_attributes[symbol][:value]={} if symbol_attributes[symbol][:value].nil?
        symbol_attributes[symbol][:value][filename]=value
      end
    end
    
    if (symbol.nil?) &&  line=~/^(\w+):/ then
			symbol=$1
		end
    
		comment=nil
		if (!(symbol.nil?) && line=~/;(.*)/) then
			comment=$1
		end
    
		if ((comment.nil?) && (!last_comment.nil?) && (!symbol.nil?)) then
			comment=last_comment
		end

    if !symbol_attributes[symbol].nil?  && !comment.nil? then
      symbol_attributes[symbol][:comment]={} if symbol_attributes[symbol][:comment].nil?
      symbol_attributes[symbol][:comment][filename]=comment      
    end

		if line=~/^;(.*)/ then
			if last_comment.nil? then
				last_comment=""
			else
        last_comment+="\n"				
			end
			last_comment+=$1
		else
			last_comment=nil
		end

	end

end

symbol_names=symbol_attributes.keys.sort
source_files=[]
require 'markaby'

[:function,:variable,:constant].each do |symbol_type|
  mab = Markaby::Builder.new
  mab.html do
    head do
      link(:rel=>"stylesheet", :href=>"ca65-doc-style.css",:type=>"text/css")
    end    
    body do    
      h2 "#{symbol_type}s"
      table  do
        tr do 
          th "#{symbol_type}"
          th "defined in"
        end
        symbol_names.each do |symbol|
          if symbol_attributes[symbol][:type]==symbol_type then
            tr do 
                td symbol 
                count=0
                td do
                  symbol_attributes[symbol][:defined_in].each do |filename|
                    count+=1
                    text ", " unless count==1
                    a(:href=>"#{html_filenames[filename]}##{symbol_type}s", :target=>"docwin"){filename}
                    source_files<<filename unless source_files.include?(filename)
                  end
                end
              end
          end
        end
      end
    end
  end
  File.open("#{output_dir}/#{symbol_type}_index.html","w") <<mab.to_s
end


mab = Markaby::Builder.new
mab.html do
  head do
    link(:rel=>"stylesheet", :href=>"ca65-doc-style.css",:type=>"text/css")
  end

  body do    
    h1 "#{documentation_title}"

    h2 "files"
    table  do
      tr do 
        th "file"
        th "symbols"
      end        
      source_files.sort.each do |filename|
        tr do
          td {a(:href=>"#{html_filenames[filename]}", :target=>"docwin"){filename}}
          symbols_in_file=(symbol_names.collect{|symbol| symbol_attributes[symbol][:defined_in].include?(filename) ? symbol:nil}).compact
          td symbols_in_file.join(", ")
        end
      end
    end
  end
end
File.open("#{output_dir}/ref_index.html","w") <<mab.to_s



source_files.sort.each do |filename|
  functions_in_file=[]
  variables_in_file=[]
  constants_in_file=[]
  
  symbol_names.each do |symbol|
    symbol_attribute=symbol_attributes[symbol]
    if symbol_attribute[:defined_in].include?(filename) then
      functions_in_file<<symbol if symbol_attribute[:type]==:function
      variables_in_file<<symbol if symbol_attribute[:type]==:variable
      constants_in_file<<symbol if symbol_attribute[:type]==:constant
    end
  end

  mab = Markaby::Builder.new
  mab.html do
    head do
        link(:rel=>"stylesheet", :href=>"ca65-doc-style.css",:type=>"text/css")
    end
    body do    
      a(:href=>"ref_index.html") { h1 documentation_title} 
      h1 "File : #{filename}"
      pre file_overviews[filename] if file_overviews[filename].length>1

      if functions_in_file.length>0 then
        h2(:id=>"functions") {"functions"}
        table do
          tr do 
            th{"function"} 
            th{"description"}
          end
          functions_in_file.each do |symbol|
            tr do
              td(:id=>symbol){symbol} 
              td{pre symbol_attributes[symbol][:comment][filename] unless  symbol_attributes[symbol][:comment].nil?}
            end
          end
        end
      end

      if variables_in_file.length>0 then
        h2(:id=>"variables"){"variables"}
          table do
          tr do 
            th{"variable"} 
            th{"description"}
            th{"size (bytes)"}
          end
          variables_in_file.each do |symbol|
            tr do
              td(:id=>symbol){symbol} 
              td{symbol_attributes[symbol][:comment][filename] unless  symbol_attributes[symbol][:comment].nil?}
              td{symbol_attributes[symbol][:size][filename] unless  symbol_attributes[symbol][:size].nil?}
            end
          end
        end

      end
      
      if constants_in_file.length>0 then
        h2(:id=>"constants") {"constants"}
          table do
          tr do 
            th{"constants"} 
            th{"description"}
            th{"value"}
          end
          constants_in_file.each do |symbol|
            tr do
              td(:id=>symbol){symbol} 
              td{symbol_attributes[symbol][:comment][filename] unless  symbol_attributes[symbol][:comment].nil?}
              td{symbol_attributes[symbol][:value][filename] unless  symbol_attributes[symbol][:value].nil?}
            end
          end
        end
        
      end
      h2{ "implementation"}
      pre(:id=>:code) {File.open("#{codebase_dir}/#{filename}").read.gsub("\t","  ")}
    end
  end
  
  File.open("#{output_dir}/#{html_filenames[filename]}","w") <<mab.to_s
end


#markaby doesn't like framesets so do the index.html frameset the 'old fashioned' way
File.open("#{output_dir}/ref_frames.html","w") << <<EOF
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head> 
  <title>#{documentation_title}</title>
</head>
<frameset rows="20%, 80%" border=1>
  <frameset cols="5,5,5" border=1>
    <frame src="function_index.html"  title="functions" name="functions" />
    <frame src="variable_index.html"   title="variables" name="variables"/>
    <frame src="constant_index.html"  title="constants" name="constants"/>
  </frameset>
  <frame name="docwin"  src="ref_index.html"   />

</frameset>    
EOF

end



if __FILE__ == $0 then
  #run from command line
  codebase_dir=Dir.pwd
  output_dir="doc"
  codebase_title=File.basename(codebase_dir) 
  document_ca65_source_as_html(codebase_dir,codebase_title,output_dir)
end