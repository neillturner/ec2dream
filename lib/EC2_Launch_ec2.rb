class EC2_Launch


 def launch_instance
    puts "launch.launch_instance"
     platform = @ec2_main.settings.get("EC2_PLATFORM")
    if @launch['Image_Id'].text != nil and @launch['Image_Id'].text != ""
        server = @launch['Image_Id'].text
    else 
        error_message("Error","Image ID not specified")
        return
    end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Server Image "+server)
    if answer == MBOX_CLICKED_YES
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
       launch_parm = Hash.new
       if platform == "eucalyptus"
          if @launch['Addressing'].text != nil and  @launch['Addressing'].text != ""
             launch_parm[:addressing] =  @launch['Addressing'].text
          end
       end   
       if @launch['Minimum_Server_Count'].text != nil and @launch['Minimum_Server_Count'].text != ""
         launch_parm[:min_count]= @launch['Minimum_Server_Count'].text
       else
         launch_parm[:min_count]= "1"
       end
       if @launch['Maximum_Server_Count'].text != nil and @launch['Maximum_Server_Count'].text != ""
         launch_parm[:max_count]= @launch['Maximum_Server_Count'].text
       else
         launch_parm[:max_count]= "1"
       end
       if @launch['Instance_Type'].text != nil and @launch['Instance_Type'].text != ""
         launch_parm[:instance_type]= @launch['Instance_Type'].text
       end
       if @launch['Keypair'].text != nil and @launch['Keypair'].text != ""
          launch_parm[:key_name]= @launch['Keypair'].text
       else 
          error_message("Launch Error","Keypair not specified")
          return
       end
       g = Array.new
       g[0] = [@launch['Security_Group'].text]
       if @launch['Additional_Security_Groups'].text != nil and @launch['Additional_Security_Groups'].text != ""
          a = @launch['Additional_Security_Groups'].text
          i = 1
          sa = (a).split(",")
          sa.each do |s|
            g[i] = s
            i = i+1
          end          
       end
       it = (@launch['Instance_Type'].text).downcase
       launch_parm[:group_names] = g 
       if @launch['Availability_Zone'].text != nil and @launch['Availability_Zone'].text != ""
             launch_parm[:availability_zone]= @launch['Availability_Zone'].text
       end
       launch_parm[:user_data] = ""
       if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
             launch_parm[:user_data]= @launch['User_Data'].text
       end
       if @launch['User_Data_File'].text != nil and @launch['User_Data_File'].text != ""
           fn = @launch['User_Data_File'].text
           d = ""
           begin 
              f = File.open(fn, "r")
	      d = f.read
              f.close
           rescue 
              puts "***Error could not read user data file"
              error_message("Launch Error","Could not read User Data File")
              return
           end
           if launch_parm[:user_data] != nil and launch_parm[:user_data] != ""
              launch_parm[:user_data]=launch_parm[:user_data]+","+d
           else
              launch_parm[:user_data]=d
           end   
       end
       if @launch['Monitoring_State'].itemCurrent?(1)
            launch_parm[:monitoring_enabled] = "true"
       end
       if platform != "eucalyptus"
          if @launch['Disable_Api_Termination'].itemCurrent?(1)
            launch_parm[:disable_api_termination] = "false"
          else
            launch_parm[:disable_api_termination] = "true"
          end
       end
       if @launch['Image_Root_Device_Type'].text != nil and  @launch['Image_Root_Device_Type'].text == "ebs"
          if @launch['Instance_Initiated_Shutdown_Behavior'].itemCurrent?(1)
             launch_parm[:instance_initiated_shutdown_behavior] = "terminate"
          else
             launch_parm[:instance_initiated_shutdown_behavior] = "stop"
          end
       end   
       if @launch['Additional_Info'].text != nil and @launch['Additional_Info'].text != ""
             launch_parm[:additional_info]= @launch['Additional_Info'].text
       end
       bm = Array.new
       if @image_bm.size>0
          bm = @image_bm.array
       end
       if @block_mapping.size>0
           bm = bm + @block_mapping.array
       end	
	 if bm.size>0 
	   i=0
           bm.each do |m|
	        sa = (m[:ebs_snapshot_id]).split"/"
		  if sa.size>1
                   m[:ebs_snapshot_id]=sa[1]
	        end
              bm[i]=m
              i = i+1
           end
           #if @launch['Image_Root_Device_Type'].text != "ebs" or bm.size>1
              launch_parm[:block_device_mappings] = bm
           #end   
       end 
       save
       puts "launch server "+server
       item_server = ""
       item = []
       begin
          item = ec2.launch_instances(server, launch_parm)
       rescue 
          error_message("Launch of Server Failed",$!.to_s)
          return
       end
       instances = []
       item.each do |r|
          if item_server == ""
             if r[:groups][0][:group_name] == nil
                gi = r[:groups][0][:group_id]
             else
                gi = r[:groups][0][:group_name]
             end   
    	     item_server = gi+"/"+r[:aws_instance_id]
          end
          puts "item server #{item_server}"
          instances.push(r[:aws_instance_id]) 
          @ec2_main.serverCache.addInstance(r)
       end
       begin 
          if @resource_tags  != nil and @resource_tags.empty == false
             instances.each do |s| 
                @resource_tags.assign(s)
             end
          end   
       rescue
          error_message("Create Tags Failed",$!.to_s)
          return
       end         
       if item_server != ""
          @ec2_main.server.load_server(item_server)
          @ec2_main.tabBook.setCurrent(1)
       end   
    end
   end 
 end 
 
 def request_spot_instance
     puts "launch.request_spot_instance"
     platform = @ec2_main.settings.get("EC2_PLATFORM")
     if platform != "amazon"  
        error_message("Not Supported","Spot Requests not supported on #{platform}")
        return
     end
     if @launch['Image_Id'].text != nil and @launch['Image_Id'].text != ""
         server = @launch['Image_Id'].text
     else 
         error_message("Error","Image ID not specified")
         return
     end
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Request","Confirm Spot Instance Request of Server Image "+server)
     if answer == MBOX_CLICKED_YES
      ec2 = @ec2_main.environment.connection
      if ec2 != nil
        launch_parm = Hash.new
        launch_parm[:image_id]=server
        launch_parm[:spot_price]= @launch['Spot_Price'].text
        if @launch['Maximum_Server_Count'].text != nil and @launch['Maximum_Server_Count'].text != ""
          launch_parm[:instance_count]= @launch['Maximum_Server_Count'].text
        else
          launch_parm[:instance_count]= "1"
        end
        if @launch['Instance_Type'].text != nil and @launch['Instance_Type'].text != ""
          launch_parm[:instance_type]= @launch['Instance_Type'].text
        end
        if @launch['Keypair'].text != nil and @launch['Keypair'].text != ""
           launch_parm[:key_name]= @launch['Keypair'].text
        else 
           error_message("Launch Error","Keypair not specified")
           return
        end
        g = Array.new
        if @launch['Additional_Security_Groups'].text == nil or @launch['Additional_Security_Groups'].text == ""
           g[0] = [@launch['Security_Group'].text]
        else
           g[0] = @launch['Security_Group'].text
           a = @launch['Additional_Security_Groups'].text
           i = 1
           a.each(",") do |s|
            g[i] = s[0..s.length-1]
            i = i+1
           end 
        end
        it = (@launch['Instance_Type'].text).downcase
        launch_parm[:group_names] = g 
        if @launch['Availability_Zone'].text != nil and @launch['Availability_Zone'].text != ""
              launch_parm[:availability_zone]= @launch['Availability_Zone'].text
        end
        launch_parm[:user_data] = ""
        if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
              launch_parm[:user_data]= @launch['User_Data'].text
        end
        if @launch['User_Data_File'].text != nil and @launch['User_Data_File'].text != ""
            fn = @launch['User_Data_File'].text
            d = ""
            begin 
               f = File.open(fn, "r")
 	      d = f.read
               f.close
            rescue 
               puts "***Error could not read user data file"
               error_message("Launch Error","Could not read User Data File")
               return
            end
            if launch_parm[:user_data] != nil and launch_parm[:user_data] != ""
               launch_parm[:user_data]=launch_parm[:user_data]+","+d
            else
               launch_parm[:user_data]=d
            end   
        end
        if @launch['Monitoring_State'].itemCurrent?(1)
             launch_parm[:monitoring_enabled] = "true"
        end
       # currently block mappings not supported on spot instance requests.
       # if @block_mapping != nil and @block_mapping.size>0
       #      launch_parm[:block_device_mappings] = @block_mapping
       # end        
        save
        puts "request spot instance "+server
        item = {}
        begin
           item = ec2.request_spot_instances(launch_parm)
        rescue
           error_message("Spot Instance Request Failed",$!.to_s)
           return 
        end
        begin 
           if @resource_tags  != nil and @resource_tags.empty == false
              item.each do |r|
                 @resource_tags.assign(r[:spot_instance_request_id])
              end   
           end   
        rescue
          error_message("Create Tags Failed",$!.to_s)
          return
       end       
      end
     end 
 end
 
 def load(sec_grp)
   puts "Launch.load"
   if @ec2_main.settings.get("EC2_PLATFORM") == "openstack"
      load_ops(sec_grp)
   else   
      clear_panel      
      @type = "ec2"
      @profile_type = "secgrp"
      @profile_folder = "launch"
      @frame1.show()
      @frame2.hide()
      @frame3.hide()
      @frame4.hide()
      @profile = sec_grp
      @launch['Security_Group'].text = @profile
      @launch['Security_Group'].enabled = false
      @launch['Chef_Node'].text = @profile
      @launch['Image_Id'].enabled = true
      @launch['Image_Id_Button'].enabled = true
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
        ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_tags.rb"
        if File.exists?(fn)
           @resource_tags = EC2_ResourceTags.new(@ec2_main) 
           @resource_tags.load(ft)
	     @launch['Tags'].text=@resource_tags.show
        else
           @resource_tags = nil
        end        
        load_panel('Security_Group')
        load_panel('Chef_Node')
        load_panel('Additional_Security_Groups')
	load_panel('Addressing')
        load_panel('Image_Id')
        load_panel('Image_Manifest')
        load_panel('Image_Architecture')
        load_panel('Image_Visibility')
        load_panel('Image_Root_Device_Type')
        load_panel('Spot_Price')
        load_panel('Minimum_Server_Count')
        load_panel('Maximum_Server_Count')
        load_panel('Instance_Type')
        load_panel('Keypair')
        load_panel('Availability_Zone')
        load_panel('User_Data')
        load_panel('User_Data_File')
        load_monitoring_state()
        load_boolean_state('Disable_Api_Termination')
        load_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
        load_panel('Additional_Info')
        load_panel('EC2_SSH_User')
        load_panel('EC2_SSH_Private_Key')
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
           load_panel('Putty_Private_Key')
        end
        load_panel('Win_Admin_Password')
        @block_mapping.load_from_properties(@properties,"BlockMapping",@launch['Block_Devices'])
        @image_bm.load_from_properties(@properties,"Image_Bm",@launch['Image_Block_Devices']) 
        @launch_loaded = true
      else
        # default to empty values
        keypair = @ec2_main.settings.get('KEYPAIR_NAME')
        if keypair != nil and keypair != ""
         put('Keypair',keypair)
        end
        @launch_loaded = true
      end
      load_notes
      @ec2_main.app.forceRefresh
   end   
 end 
   
   def load_image
      puts "Launch.load_image"
      ec2 = @ec2_main.environment.connection
      if ec2 != nil
       image_id = @properties['Image_Id']
       if image_id != nil and image_id != ""
         begin 
          ec2.describe_images([image_id]).each do |r|
            #puts r 
            put('Image_Manifest',r[:aws_location])
            put('Image_Architecture',r[:aws_architecture])
            if r[:aws_is_public] == true
              put('Image_Visibility',"Public")
            else
              put('Image_Visibility',"Private")
            end
            it = @launch['Instance_Type'].text
            if it == nil or it == ""
	       put('Instance_Type',"m1.small")
            end
            put('Image_Root_Device_Type',r[:root_device_type])
            @image_bm.load(r,@launch['Image_Block_Devices'])
          end            
         rescue
          puts "**Error Image not found"
          put('Image_Manifest',"*** Not Found ***")
          error_message("Error","Launch Profile: Image Id not found")
         end
       end   
      end
   end
   
   def load_profile(image)
         puts "Launch.load_profile"
         @type = "ec2"
         sa = (image).split("/")
         image_id = image 
         if sa.size>1
            image_id = sa[1].rstrip
         end         
         @frame1.show()
         @frame2.hide()
	 @frame3.hide()
	 @frame4.hide()
         @profile_type = "image"
         @profile_folder = "image"
         if !File.exists?(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
            Dir.mkdir(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
         end    
         clear_panel
         @profile = image_id
         @launch['Image_Id'].text = @profile
         @launch['Security_Group'].enabled = true
         @launch['Image_Id'].enabled = false
         @launch['Image_Id_Button'].enabled = false
         @properties['Image_Id'] = @profile
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
           load_panel('Security_Group')
           load_panel('Chef_Node')
           load_panel('Additional_Security_Groups')
	   load_panel('Addressing')
           load_panel('Image_Id')
           load_panel('Image_Manifest')
           load_panel('Image_Architecture')
           load_panel('Image_Visibility')
           load_panel('Image_Root_Device_Type')
           load_panel('Spot_Price')
           load_panel('Minimum_Server_Count')
           load_panel('Maximum_Server_Count')
           load_panel('Instance_Type')
           load_panel('Keypair')
           load_panel('Availability_Zone')
           load_panel('User_Data')
           load_panel('User_Data_File')
           load_monitoring_state()
           load_boolean_state('Disable_Api_Termination')
           load_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
           load_panel('Additional_Info')
           load_panel('EC2_SSH_User')
           load_panel('EC2_SSH_Private_Key')
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
              load_panel('Putty_Private_Key')
           end
           load_panel('Win_Admin_Password')        
           @launch_loaded = true
         else
           keypair = @ec2_main.settings.get('KEYPAIR_NAME')
           if keypair != nil and keypair != ""
            put('Keypair',keypair)
           end
           pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
   	   if pk != nil and pk != ""
   	      put('EC2_SSH_Private_Key',pk)
           end
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
   	      ppk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
   	      if ppk != nil and ppk != ""
   	         put('Putty_Private_Key',ppk)
              end        
           end
           @launch_loaded = true
         end
         @block_mapping.load_from_properties(@properties,"BlockMapping",@launch['Block_Devices'])
         @image_bm.load_from_properties(@properties,"Image_Bm",@launch['Image_Block_Devices'])          
         load_notes
         @ec2_main.app.forceRefresh
   end 
   
   def load_monitoring_state
     if @properties['Monitoring_State'] == 'enabled'
        @launch['Monitoring_State'].setCurrentItem(1)
     else
        @launch['Monitoring_State'].setCurrentItem(0)
     end   
   end
   
   def load_boolean_state(prop)
        if @properties[prop] == 'true'
           @launch[prop].setCurrentItem(0)
        end   
        if @properties[prop] == 'false'
           @launch[prop].setCurrentItem(1)
        end   
   end
   
   def load_shutdown_behaviour(prop)
        if @properties[prop] == 'stop'
           @launch[prop].setCurrentItem(0)
        end   
        if @properties[prop] == 'terminate'
           @launch[prop].setCurrentItem(1)
        end   
   end   
   
   def load_panel(key)
    if @properties[key] != nil
      @launch[key].text = @properties[key]
    end
   end 
   
   def clear_panel
     puts "Launch.clear_panel" 
     @type = ""
     @profile = ""
     @resource_tags = nil 
     clear('Security_Group')
     clear('Chef_Node')
     clear('Additional_Security_Groups')
     clear('Tags')
     clear('Addressing')
     clear('Image_Id')
     clear('Image_Manifest')
     clear('Image_Architecture')
     clear('Image_Visibility')
     clear('Image_Root_Device_Type')
     clear('Spot_Price')
     clear('Minimum_Server_Count')
     clear('Maximum_Server_Count')
     clear('Instance_Type')
     clear('Keypair')
     clear('Availability_Zone')
     clear('User_Data')
     clear('User_Data_File')
     clear_monitoring_state
     clear_boolean_state('Disable_Api_Termination')
     clear_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
     clear('Additional_Info')
     clear('EC2_SSH_User')
     clear('EC2_SSH_Private_Key')
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        clear('Putty_Private_Key')
     end
     clear('Win_Admin_Password')
     @block_mapping.clear(@properties,"BlockMapping",@launch['Block_Devices'])
     @image_bm.clear(@properties,"Image_Bm",@launch['Image_Block_Devices'])
     clear_notes     
     @launch_loaded = false
     #puts @launch['Security_Group'].text
   end 
   
   def clear_monitoring_state
      @properties['Monitoring_State'] = "disabled"
      @launch['Monitoring_State'].setCurrentItem(0)
   end 
   
   def clear_boolean_state(prop)
      @properties[prop] = "false"
      @launch[prop].setCurrentItem(1)
   end

   def clear_shutdown_behaviour(prop)
      @properties[prop] = "stop"
      @launch[prop].setCurrentItem(0)
   end   
   
   def clear(key)
      @properties[key] = ""
      @launch[key].text = ""
   end  
   
   def get(key)
      return @properties[key]
   end
   
   def put(key,value)
      puts "Launch.put "+key
      @properties[key] = value
      @launch[key].text = value
   end 
   
   def save
      puts "Launch.save"
      load_image
      save_launch('Security_Group')
      save_launch('Chef_Node')
      save_launch('Additional_Security_Groups')
      save_launch('Addressing')
      save_launch('Image_Id')
      save_launch('Image_Manifest')
      save_launch('Image_Architecture')
      save_launch('Image_Visibility')
      save_launch('Image_Root_Device_Type')
      save_launch('Spot_Price')
      save_launch('Minimum_Server_Count')
      save_launch('Maximum_Server_Count')
      save_launch('Instance_Type')
      save_launch('Keypair')
      save_launch('Availability_Zone')
      save_launch('User_Data')
      save_launch('User_Data_File')
      save_monitoring_state()
      save_boolean_state('Disable_Api_Termination')
      save_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
      save_launch('Additional_Info')
      save_launch('EC2_SSH_User')
      save_launch('EC2_SSH_Private_Key')
      if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
         save_launch('Putty_Private_Key')
      end
      save_launch('Win_Admin_Password')
      @block_mapping.save(@properties,"BlockMapping")
      @image_bm.save(@properties,"Image_Bm")
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
         if @resource_tags != nil
            ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_tags.rb"
            puts "saving #{ft}"
            @resource_tags.save(ft)  
         end
         save_notes
         @launch_loaded = true
      rescue
         puts "launch loaded false"
         @launch_loaded = false      
      end
   end
   
   def delete
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
              load(@profile)
            end
         else
            error_message("Error","No Launch Profile for "+@profile+" to delete") 
         end
      rescue 
      end
   end 
   
  def image_info
     puts "Launch.image_info" 
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
       img = @launch['Image_Id'].text
       ec2.describe_images([img]).each do |r|
         put('Image_Manifest',r[:aws_location])
         put('Image_Architecture',r[:aws_architecture])
         public = r[:aws_is_public]
         if public == true 
            put('Image_Visibility','public')
         else
            put('Image_Visibility','private')
         end
	   it = @launch['Instance_Type'].text
         if it == nil or it == ""
            if r[:aws_architecture] == "x86_64"
	         put('Instance_Type',"m1.large")
	      else
	         put('Instance_Type',"m1.small")
            end 
         end
         put('Image_Root_Device_Type',r[:root_device_type])
         @image_bm.load(r,@launch['Image_Block_Devices'])
         puts "bm*** #{@launch['Image_Block_Devices']}"
       end
    end
  end 
   
   def save_monitoring_state
        if @launch['Monitoring_State'].itemCurrent?(1) 
	    @properties['Monitoring_State']="enabled"  
	else
	    @properties['Monitoring_State']="disabled" 
        end
   end
   
   def save_boolean_state(prop)
        if @launch[prop].itemCurrent?(1) 
	    @properties[prop]="false"  
	else
	    @properties[prop]="true" 
        end
   end
   
   def save_shutdown_behaviour(prop)
        if @launch[prop].itemCurrent?(1) 
   	    @properties[prop]="terminate"  
   	else
   	    @properties[prop]="stop" 
        end
   end

   def save_launch(key)
     puts "Launch.save_setting"  
     if @launch[key].text != nil
       @properties[key] =  @launch[key].text
     else
       @properties[key] = nil
     end
   end
   
  
def clear_notes
    @text_area.text = ""
    @rds_text_area.text = ""
    @ops_text_area.text = ""
    @loaded = false
end
  
def load_notes
   if !File.directory?(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
       FileUtils.mkdir_p @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder
   end
   fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".txt"
   begin
      if File.exists?(fn) == false
         File.new(fn, "w")
      end
      f = File.open(fn, "r")
      if @type == "rds"
         @rds_text_area.text = f.read
      elsif @type == "ops"
         @ops_text_area.text = f.read
      else
         @text_area.text = f.read
      end
      f.close
      @loaded = true
   rescue
      @loaded = false
   end
end        
  
def save_notes
   if @type == "rds"
      textOutput = @rds_text_area.text
   elsif @type == "ops"
      textOutput = @ops_text_area.text      
   else   
      textOutput = @text_area.text
   end   
   fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".txt"
   begin
      File.open(fn, 'w') do |f|  
         f.write(textOutput)
         f.close
      end
   rescue
   end
end 


end
