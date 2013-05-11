 def edit(filename)
    if filename == nil or filename == ""
       puts "ERROR: no file specified"
    elsif !File.exists?(filename)
       puts "ERROR: file #{filename} not found"
    else   
 	 editor = $ec2_main.settings.get_system('EXTERNAL_EDITOR')
 	 puts "#{editor} #{filename}"
	 system editor+" "+filename
    end	 
 end	 
