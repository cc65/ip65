class FileList 
  
  FILE_EXTENSIONS=[".prg",".pg2",".d64",".sid"]

  def initialize(dir)
    log_msg("building file list for #{dir}")    
    @file_list={}
    @base_dir=dir
    read_dir(dir,dir)
#    puts @file_list.keys.sort.join("\n")
  end
  
  def [](path_mask)
    path_mask.gsub!("//","/") 
    full_filename="#{@base_dir}/#{path_mask}"
    puts full_filename

    if (path_mask=~/^\$\/?(.*)\*(\..{1,3}$)/)
      target_extension=$2.downcase
      dirname="/#{$1}".sub(/\/$/,'') # trim any trailing /
      
      current_dir=@file_list[dirname]
      raise "invalid directory #{dirname}" if current_dir.nil?
      s=""
      s<<"$/\000" unless dirname==""
      slash_index=0
      while !(slash_index.nil?)
        slash_index=dirname.index("/",slash_index+1)
        break if slash_index.nil?
        subdir=dirname[0,slash_index]
        normalised_subdir="$/#{subdir}".gsub("//","/").gsub("//","/")
        s<<"#{normalised_subdir}\000"
      end
      current_dir[:directories].each do |directory_attributes|
        subdir=directory_attributes[0]
        normalised_subdir="$/#{subdir}".gsub("//","/").gsub("//","/")
        s<<"#{normalised_subdir}\000"
      end

      current_dir[:files].each do |filename|
        s<<"#{filename}\000" if filename.downcase=~/#{target_extension}$/
      end
      s<<0.chr if s.length==0 #make sure there is at least one 'empty' string
      s<<0.chr
      return s
    elsif (FileTest.file?(full_filename))
      return File.open(full_filename,"rb").read      
    else
      raise "invalid path mask #{full_filename}"
    end
  end
  
private

  def read_dir(dir,base_dir)
    dir_contents={:files=>[],:directories=>[]}  
    Dir.glob("#{dir}/**").each do |filename|
      relative_filename=filename.sub(/#{base_dir}/,'')
      if File.ftype(filename)=="directory" 
          dir_contents[:directories]<<[relative_filename,read_dir(filename,base_dir)]
      elsif (relative_filename=~/(\..{1,3})$/)        
        ext=$1.downcase 
          dir_contents[:files]<<relative_filename if FILE_EXTENSIONS.include?(ext)
        else puts "skipping #{relative_filename}"
      end
    end
    @file_list[dir.sub(/#{base_dir}/,'')]=dir_contents
  end    
end