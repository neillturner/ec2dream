class EC2_Launch

 def launch_google_instance
    puts "launch.launch_google_instance"
	server = ""
    if @google_launch['Name'].text != nil and @google_launch['Name'].text != ""
        server = @google_launch['Name'].text
    else 
        error_message("Error","Name not specified")
        return
    end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Server "+server)
    if answer == MBOX_CLICKED_YES
       launch_parm = Hash.new
       #if @google_launch['Keyname'].text != nil and @google_launch['Keyname'].text != ""
       #   launch_parm['key_name']= @google_launch['Keyname'].text
       #end
       launch_parm['machineType'] = @google_launch['Flavor'].text
       zone = @google_launch['Availability_Zone'].text
       #launch_parm['metadata'] = ""
       #if @launch['User_Data'].text != nil and @google_launch['User_Data'].text != ""
       #      launch_parm['metadata']= @google_launch['User_Data'].text
       #end
       google_save
	   disks = []
	   disk = @ec2_main.environment.volumes.get(@google_launch['Boot_Disk'].text)
	   disks.push(disk.get_as_boot_disk(true))
	   additional_disks = (@google_launch['Disks'].text).split(',')
	   additional_disks.each do |d|
	      disk = @ec2_main.environment.volumes.get(d)
		  disks.push(disks) if disks != nil 
	   end 
       launch_parm['disks'] = disks	   
       networks = (@google_launch['Network'].text).split(',')
	   launch_parm['network'] = networks[0] if !networks.empty? 
	   launch_parm['externalIp'] = @google_launch['External_Ip'].text if !(@google_launch['External_Ip'].text).empty? 
	
       puts "launch server "+server
        begin
          puts "Insert #{server}, #{zone}, #{launch_parm}"
          r =  @ec2_main.environment.servers.insert_server(server, zone, launch_parm)
          puts "Launch id #{r['id']}  clientOperationId #{r['clientOperationId']} targetId #{r['targetId']}"
          puts "Launch response #{r}"
		  if r['error'] != nil 
		    r['error']['errors'].each do |e|
		      puts "INSERT SERVER ERROR: #{e['code']} #{e['location']} #{e['message']}"
            end
          end			
       rescue
          error_message("Launch of Server Failed",$!)
          return
       end
	   sleep 7 
       if @google_metadata != nil and @google_metadata.empty == false
	      @ec2_main.environment.servers.set_meta(server, $google_zone, @google_metadata.get)
       end  
       if @google_launch['Tags'].text != nil and @google_launch['Tags'].text == false
	      t = (@google_launch['Tags'].text).split(',')
	      @ec2_main.environment.servers.set_tags(server, $google_zone, t)
       end     	  	   
       @ec2_main.treeCache.refresh
	   @ec2_main.server.load_server(server)
       @ec2_main.tabBook.setCurrent(1)
    end
 end 
 
 
 
  def load_google(parm)
       puts "Launch.load_google"
       clear_google_panel      
       @type = "google"
       @profile_type = ""
       @profile_folder = "launch"
       @frame1.hide()
       @frame3.hide()
       @frame4.hide()
       @frame5.hide()
	   @frame6.show()
       @profile = parm
       @google_launch['Name'].text = @profile
       @google_launch['Name'].enabled = false
       @google_launch['Chef_Node'].text = @profile
       fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
       if File.exists?(fn)
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
         load_google_panel('Chef_Node')
		 load_google_panel('Puppet_Manifest')
         load_google_panel('Boot_Disk')
		 load_google_panel('Boot_Disk_Device')
		 load_google_panel('Disks')
         load_google_panel('Flavor')
         load_google_panel('Admin_Password')
         load_google_panel('EC2_SSH_User')
         load_google_panel('SSH_Private_Key')
         load_google_panel('Putty_Private_Key')
		 load_google_panel('Tags')   
         load_google_panel('Availability_Zone')         
         ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_metadata.rb"
         if File.exists?(fn)
           @google_metadata = GOG_Metadata.new(@ec2_main) 
           @google_metadata.load(ft)
	       @google_launch['User_Data'].text=@google_metadata.show
        else
           @google_metadata = nil
        end  		 
 	     load_google_panel('Network')
         load_google_panel('External_Ip')       
         @launch_loaded = true
       else
         # default to empty values
         @google_launch['Name'].enabled = true
         @launch_loaded = true
       end
       load_notes
       @ec2_main.app.forceRefresh
 end 
 
   def clear_google_panel
     puts "Launch.clear_google_panel" 
     @type = "google"
     @profile = ""
     @resource_tags = nil 
	 @properties = {}
     @frame1.hide()
     @frame3.hide()
     @frame4.hide()
     @frame5.hide()
	 @frame6.show()
     google_clear('Chef_Node')
	 google_clear('Puppet_Manifest')
     google_clear('Admin_Password')
     @google_launch['Name'].text = ""
     @google_launch['Name'].enabled = true
     google_clear('Boot_Disk')
	 #google_clear('Boot_Disk_Device')
	 google_put('Boot_Disk_Device',"/dev/sda1")
	 google_clear('Disks')
     google_clear('Flavor')
	 google_clear('Tags')
	 google_put('Availability_Zone',$google_zone)
     #google_clear('Availability_Zone')         
     google_clear('User_Data')
	 @google_metadata = nil
     google_clear('Network')
     google_clear('External_Ip')        
     google_clear('EC2_SSH_User')
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        google_clear('Putty_Private_Key')
     end
     clear_notes     
     @launch_loaded = false
    end  
   
   def google_clear(key)
      if key == 'Admin_Password'
         @properties.each_pair do |key, value|
            if key.start_with?('Admin_Password')
               @properties[key] = ""
            end
         end   
      else   
         @properties[key] = ""
      end   
      @google_launch[key].text = ""
   end     

   def google_put(key,value)
      puts "Launch.google_put "+key
      if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
         @properties[key+"_"+@properties['Name']] = value
         @google_launch[key].text = value      
      else
         @properties[key] = value
         @google_launch[key].text = value
      end   
   end 
   
   def google_append(key,value)
      puts "Launch.google_dappen "+key
	  if @properties[key] == nil or @properties[key] == ""
           @properties[key] = value
 	  else 
           @properties[key] = "#{@properties[key]},value"
      end 
	  if @google_launch[key].text == nil or @google_launch[key].text == ""
            @google_launch[key].text = value
	  else 
           @google_launch[key].text = "#{@google_launch[key].text},value"
      end 		  
   end 

   def google_save
     puts "Launch.save_google"
     @profile = @google_launch['Name'].text
     @profile_folder = "launch"
     if @profile == nil or @profile == ""
        error_message("Error","No Server Name specified") 
     else 
      @properties = {}	 
      save_google_launch('Chef_Node')
	  save_google_launch('Puppet_Manifest')
      save_google_launch('Boot_Disk')
	  save_google_launch('Boot_Disk_Device')
	  save_google_launch('Disks')
      save_google_launch('Flavor')
      save_google_launch('Admin_Password')
      save_google_launch('EC2_SSH_User')
      save_google_launch('SSH_Private_Key')
      save_google_launch('Putty_Private_Key')
	  save_google_launch('Tags')
      save_google_launch('Availability_Zone')       
 	  save_google_launch('Network')
      save_google_launch('External_Ip')       
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
        if @google_metadata != nil
            ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_metadata.rb"
            puts "saving #{ft}"
            @google_metadata.save(ft)  
         end		 
         save_notes
         @launch_loaded = true
      rescue
         puts "launch loaded false"
         @launch_loaded = false      
      end
     end 
   end
   
   def load_google_panel(key)
       if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	  @google_launch[key].text = @properties[key+"_"+@properties['Name']]    
       elsif @properties[key] != nil
         @google_launch[key].text = @properties[key]
       end
   end 
   
   def save_google_launch(key)
        puts "Launch.save_google_launch #{key}" 
        if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	   @properties[key+"_"+@properties['Name']] = @google_launch[key].text
        elsif @google_launch[key].text != nil
          @properties[key] =  @google_launch[key].text
        else
          @properties[key] = nil
        end
   end

   def google_get(key)
      if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	 return @properties[key+"_"+@properties['Name']]
      else
          return @properties[key]
      end   
   end

   def google_delete
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      begin
         if File.exists?(fn)
            answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of launch profile "+@profile)
            if answer == MBOX_CLICKED_YES
               File.delete(fn)
               ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_tags.rb"
	       if File.exists?(ft)
                  File.delete(fn)
               end
              load_google(@profile)
            end
         else
            error_message("Error","No Launch Profile for "+@profile+" to delete") 
         end
      rescue 
      end
   end 

end
