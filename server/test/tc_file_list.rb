lib_path=File.expand_path(File.dirname(__FILE__)+"//..//lib")
$:.unshift(lib_path) unless $:.include?(lib_path)

require 'test/unit'
require 'file_list'


BOOT_DIR=File.expand_path(File.dirname(__FILE__)+'/../boot')

def log_msg(msg)
  puts msg
end

class TestFileList <Test::Unit::TestCase
  def test_simple_file_list
    file_list=FileList.new(BOOT_DIR)
    prg_file_list=file_list["$*.prg"]
    puts "PRG list"
    puts prg_file_list.split(0.chr).join("\n")

    assert(prg_file_list.length>0,"file list for $*.prg should not be empty")
    assert(prg_file_list=~/\000\000$/,"$*.prg file list should end in two zeros")
    assert(prg_file_list=~/\.prg/i,"$*.prg file list should contain at least one .prg file")
    assert(!(prg_file_list=~/.pg2/i),"$*.prg file list should contain no .pg2 files")
    assert(prg_file_list=~/\$\/subdir/i,"$*.prg file list should contain subdirectory")    

    pg2_file_list=file_list["$/*.pg2"]
    assert(pg2_file_list.length>0,"file list for $*.pg2 should not be empty")
    assert(pg2_file_list=~/\000\000$/,"$*.pg2 file list should end in two zeros")
    assert(pg2_file_list=~/\.pg2/i,"$*.pg2 file list should contain at least one .pg2 file")
    assert(!(pg2_file_list=~/.prg/i),"$*.pg2 file list should contain at no .prg files")  


    puts "PG2 list"
    puts pg2_file_list.split(0.chr).join("\n")

    subdir_file_list=file_list["$/subdir/*.prg"]
    puts "SUBDIR list"
    puts subdir_file_list.split(0.chr).join("\n")

    assert(subdir_file_list.length>0,"file list for $/subdir/*.prg should not be empty")
    assert(subdir_file_list=~/\000\000$/,"$/subdir/*.prg file list should end in two zeros")
    assert(subdir_file_list=~/\.prg/i,"$/subdir/*.prg file list should contain at least one .prg file")
    assert(!(subdir_file_list=~/.pg2/i),"$/subdir/*.prg file list should contain no .pg2 files")


    empty_subdir_file_list=file_list["$/subdir/empty/*.prg"]
    puts "EMPTY SUBDIR list"
    puts empty_subdir_file_list.split(0.chr).join("\n")
#    assert_equal(2,empty_subdir_file_list.length,"file list for $/subdir/empty/*.prg should be empty")
  
    filemask="$/subdir/another_subdir/*.pg2"
    multiple_subdir_file_list=file_list[filemask]
    puts "MULTIPLE SUBDIR list"
    puts multiple_subdir_file_list.split(0.chr).join("\n")

    assert(multiple_subdir_file_list.length>2,"file list for #{filemask} should not be empty")
    assert(multiple_subdir_file_list=~/\.pg2/i,"#{filemask} file list should contain at least one .prg file")
    assert_equal("/",multiple_subdir_file_list.split(0.chr)[0],"first entry file list for #{filemask} should  be /")
    assert_equal("/subdir",multiple_subdir_file_list.split(0.chr)[1],"first entry file list for #{filemask} should  be /subdir")
    
#    puts file_list["$*.prg"]
#    puts file_list["$/subdir/*.prg"]
  end
end