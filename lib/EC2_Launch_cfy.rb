class EC2_Launch

 def launch_cfy_instance
    puts "launch.launch_cfy_instance"
    if @cfy_launch['Name'].text != nil and @cfy_launch['Name'].text != ""
        name = @cfy_launch['Name'].text
    else 
        error_message("Error","Name not specified")
        return
    end
    if @cfy_launch['Instances'].text != nil and @cfy_launch['Instances'].text != ""
        instances = @cfy_launch['Instances'].text
    else 
        error_message("Error","Instances not specified")
        return
    end
    if @cfy_launch['Memory_Size'].text != nil and @cfy_launch['Memory_Size'].text != ""
        memory_size = @cfy_launch['Memory_Size'].text
    else 
        error_message("Error","Memory Size not specified")
        return
    end
    if @cfy_launch['Type'].text != nil and @cfy_launch['Type'].text != ""
        type = @cfy_launch['Type'].text
    else 
        error_message("Error","Type not specified")
        return
    end
    if @cfy_launch['URL'].text != nil and @cfy_launch['URL'].text != ""
        url = @cfy_launch['URL'].text
    else 
        error_message("Error","URL not specified")
        return
    end  
    if @cfy_launch['Bind_Service'].text != nil and @cfy_launch['Bind_Service'].text != ""
        bind_service = @cfy_launch['Bind_Service'].text
    else 
        bind_service = ""
    end        
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of App #{name}")
    if answer == MBOX_CLICKED_YES
       puts "create app #{name}"
       name = name.strip.downcase
       framework, runtime = type.split("/")
       url = url.strip.gsub(/^http(s*):\/\//i, '').downcase
       begin
          r =  @ec2_main.environment.cfy_app.create(name, instances, memory_size, url, framework, runtime, bind_service)
       rescue
          error_message("App Creation Failed",$!)
          return
       end
       @ec2_main.server.load("#{name}/#{type}")
       @ec2_main.tabBook.setCurrent(1)
    end
 end 
 
 def load_cfy(name)
       puts "Launch.load_cfy"
       clear_cfy_panel      
       @type = "cfy"
       @profile_type = "secgrp"
       @profile_folder = "launch"
       @frame1.hide()
       @frame3.hide()
       @frame4.hide()
       @frame5.show()
       @profile = name
       @properties = {}
       @cfy_launch['Name'].text = @profile
       @cfy_launch['Name'].enabled = true
       fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
       if File.exists?(fn)
         @cfy_launch['Name'].enabled = false
         File.open(fn, 'r') do |properties_file|
            properties_file.read.each_line do |line|
               line.strip!
               if (line[0] != ?# and line[0] != ?=)
        	  i = line.index('=')
        	  if (i)
        	     @properties[line[0..i - 1].strip] = line[i + 1..-1].strip
        	  else
        	     @properties[line] = ''
        	  end
               end
            end
         end
         load_cfy_panel('Instances')
         load_cfy_panel('Memory_Size')
         load_cfy_panel('Type')         
         load_cfy_panel('URL')
         load_cfy_panel('Bind_Service')
         @launch_loaded = true
       else
         # default to empty values
         @launch_loaded = true
       end
       @ec2_main.app.forceRefresh
 end 
 
   def clear_cfy_panel
     puts "Launch.clear_cfy_panel" 
     @type = "cfy"
     @profile = ""
     @properties = {}
     @resource_tags = nil 
     @frame1.hide()
     @frame3.hide()
     @frame4.hide()
     @frame5.show()     
     cfy_clear('Name')
     @cfy_launch['Name'].enabled = true
     cfy_clear('Instances')
     cfy_clear('Memory_Size')
     cfy_clear('Type')
     cfy_clear('URL')
     @cfy_launch['URL'].text = "http://xxxxxx.cloudfoundry.com"
     cfy_clear('Bind_Service')
     @launch_loaded = false
     @ec2_main.app.forceRefresh
   end  
   
   def cfy_clear(key)
      @properties[key] = ""
      @cfy_launch[key].text = ""
   end     

   def cfy_put(key,value)
      puts "Launch.cfy_put "+key
      @properties[key] = value
      @cfy_launch[key].text = value
   end 

   def cfy_save
      puts "Launch.save_cfy"
      if @cfy_launch['Name'].text == ""
         error_message("Error","No Name specified") 
      else  
         @profile = @cfy_launch['Name'].text
         save_cfy_launch('Name')
         save_cfy_launch('Instances')
         save_cfy_launch('Memory_Size')
         save_cfy_launch('Type')
         save_cfy_launch('URL')
         save_cfy_launch('Bind_Service')
         doc = ""
         @properties.each_pair do |key, value|
            if value != nil 
               puts "#{key}=#{value}\n"
               doc = doc + "#{key}=#{value}\n"
            end 
         end      
         fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
         begin
            File.open(fn, "w") do |f|
               f.write(doc)
            end
            #save_notes
            @launch_loaded = true
         rescue
            puts "launch loaded false"
            @launch_loaded = false      
         end
      end
   end   
   
   def load_cfy_panel(key)
       if @properties[key] != nil
         @cfy_launch[key].text = @properties[key]
       end
   end 
   
   def save_cfy_launch(key)
        puts "Launch.save_cfy_launch" 
        if @cfy_launch[key].text != nil
          @properties[key] =  @cfy_launch[key].text
        else
          @properties[key] = nil
        end
   end

   def cfy_get(key)
      @properties[key]
   end

   def cfy_delete
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      begin
         if File.exists?(fn)
            answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of App profile "+@profile)
            if answer == MBOX_CLICKED_YES
               File.delete(fn)
               load_cfy(@profile)
            end
         else
            error_message("Error","No App Profile for "+@profile+" to delete") 
         end
      rescue 
      end
   end 
   
end
