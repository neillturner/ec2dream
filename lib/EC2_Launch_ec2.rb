class EC2_Launch

 def launch_instance
    puts "launch.launch_instance"
     platform = @ec2_main.settings.get("EC2_PLATFORM")
    if @launch['Image_Id'].text != nil and @launch['Image_Id'].text != ""
        server = @launch['Image_Id'].text
    else
        puts "ERROR: Image ID not specified"
        error_message("Error","Image ID not specified")
        return
    end
    vpc = nil 
    if @launch['Subnet_Id'].text != nil and @launch['Subnet_Id'].text != ""
          @ec2_main.environment.vpc.describe_subnets.each do |r|
           if r['subnetId'] == @launch['Subnet_Id'].text
             vpc = r['vpcId']
           end  
          end
          if vpc == nil  
              puts "ERROR: Subnet ID not found"
              error_message("Launch Error","Subnet ID not found")
              return          
          end
    end
    if  vpc == nil
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Server Image #{server}")
    else
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Server Image #{server} into #{vpc}")
    end
    if answer == MBOX_CLICKED_YES
       launch_parm = Hash.new
       if platform == "eucalyptus"
          if @launch['Addressing'].text != nil and  @launch['Addressing'].text != ""
             launch_parm[:addressing] =  @launch['Addressing'].text
          end
       end   
       if @launch['Minimum_Server_Count'].text != nil and @launch['Minimum_Server_Count'].text != ""
         launch_parm['MinCount']= @launch['Minimum_Server_Count'].text
       else
         launch_parm['MinCount']= "1"
       end
       if @launch['Maximum_Server_Count'].text != nil and @launch['Maximum_Server_Count'].text != ""
         launch_parm['MaxCount']= @launch['Maximum_Server_Count'].text
       else
         launch_parm['MaxCount']= "1"
       end
       if @launch['Instance_Type'].text != nil and @launch['Instance_Type'].text != ""
         launch_parm['InstanceType']= @launch['Instance_Type'].text
       end
       if @launch['Keypair'].text != nil and @launch['Keypair'].text != ""
          launch_parm['KeyName']= @launch['Keypair'].text
       else 
          error_message("Launch Error","Keypair not specified")
          return
       end
       g = []
       a = @launch['Security_Group'].text
       sa = (a).split(",")
       sa.each do |s|
          g.push(s[0..s.length-1])
       end       
       if @launch['Subnet_Id'].text != nil and @launch['Subnet_Id'].text != ""
          gi = []
          g.each do |gn|
             sg = @ec2_main.serverCache.secGrps(gn,vpc)
             gi.push(sg[:group_id]) if sg != nil
          end
          launch_parm['SecurityGroupId'] = gi
       else             
          launch_parm['SecurityGroup'] = g 
       end       
       it = (@launch['Instance_Type'].text).downcase
       if @launch['Availability_Zone'].text != nil and @launch['Availability_Zone'].text != ""
             launch_parm['Placement.AvailabilityZone']= @launch['Availability_Zone'].text
       end
       if @launch['Subnet_Id'].text != nil and @launch['Subnet_Id'].text != ""
            launch_parm['SubnetId']= @launch['Subnet_Id'].text
       end
       if @launch['Private_IP'].text != nil and @launch['Private_IP'].text != ""
            launch_parm['PrivateIpAddress']= @launch['Private_IP'].text
       end       
       launch_parm['UserData'] = ""
       if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
             launch_parm['UserData']= @launch['User_Data'].text
       end
       if @launch['User_Data_File'].text != nil and @launch['User_Data_File'].text != ""
           fn = @launch['User_Data_File'].text
           d = ""
           begin 
              f = File.open(fn, "r")
	      d = f.read
              f.close
           rescue 
              puts "ERROR: could not read user data file"
              error_message("Launch Error","Could not read User Data File")
              return
           end
           if launch_parm['UserData'] != nil and launch_parm['UserData'] != ""
              launch_parm['UserData']=launch_parm['UserData']+","+d
           else
              launch_parm['UserData']=d
           end   
       end
       if @launch['Monitoring_State'].itemCurrent?(1)
            launch_parm['Monitoring.Enabled'] = true
       end
       if platform != "eucalyptus" and platform != "cloudstack"
          if @launch['Disable_Api_Termination'].itemCurrent?(1)
            launch_parm['DisableApiTermination'] = false
          else
            launch_parm['DisableApiTermination'] = true
          end
          if @launch['Ebs_Optimized'].itemCurrent?(0)
            launch_parm['EbsOptimized'] = true
          end          
          if @launch['Image_Root_Device_Type'].text != nil and  @launch['Image_Root_Device_Type'].text == "ebs"
             if @launch['Instance_Initiated_Shutdown_Behavior'].itemCurrent?(1)
                launch_parm['InstanceInitiatedShutdownBehavior'] = "terminate" 
             else
                launch_parm['InstanceInitiatedShutdownBehavior'] = "stop"
             end
          end
       end
       bm = Array.new
       if @image_bm.size>0
          bm = @image_bm.array_fog
       end
       if @block_mapping.size>0
           bm = bm + @block_mapping.array_fog
       end	
	 if bm.size>0 
	   i=0
           bm.each do |m|
            if m != nil 
              if m['Ebs.SnapshotId'] != nil
	        sa = (m['Ebs.SnapshotId']).split"/"
		  if sa.size>1
                   m['Ebs.SnapshotId']=sa[1]
	        end
	      end  
              bm[i]=m
            end  
            i = i+1
           end
           launch_parm['BlockDeviceMapping'] = bm
       end 
       save
       puts "launch server #{server} parms #{launch_parm}"
       item_server = ""
       item = []
       begin
          #item = ec2.launch_instances(server, launch_parm)
          item =  @ec2_main.environment.servers.create_server(server, nil, nil, launch_parm)
       rescue 
          error_message("Launch of Server Failed",$!)
         return
       end
       instances = []
        item.each do |r|
          if item_server == ""
              gi = launch_group_name(r)
              #if r[:groups][0][:group_name] == nil
              #  gi = r[:groups][0][:group_id]
             #else
             #   gi = r[:groups][0][:group_name]
             #end  
             name = @launch['Name'].text
             if name != nil and name != ""
                item_server = name+"/"+r[:aws_instance_id]
             else   
    	        item_server = gi+"/"+r[:aws_instance_id]
    	     end
          end
          puts "item server #{item_server}"
          instances.push(r[:aws_instance_id]) 
          #@ec2_main.serverCache.addInstance(r)
       end
       begin 
          nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
     	  if nickname_tag != nil and nickname_tag != ""
     	     name = @launch['Name'].text
     	     sleep 5 
              instances.each do |s|
                 if s != nil and s != ""
                   ec2 = @ec2_main.environment.connection
                   if ec2 != nil
                        r = ec2.create_tags(s, {nickname_tag => name})
                   end   
                end 
             end    	  
     	  end
          if @resource_tags  != nil and @resource_tags.empty == false
             instances.each do |s| 
                @resource_tags.assign(s)
             end
          end     	  
       rescue
          error_message("Create Tags Failed",$!)
          return
       end 
       if item_server != ""
          @ec2_main.environment.servers.all(instances).each do |r|
             @ec2_main.serverCache.addInstance(r)
          end 
         #@ec2_main.treeCache.refresh
          @ec2_main.server.load_server(item_server)
          @ec2_main.tabBook.setCurrent(1)
       end   
    end
 end 
 
 def launch_group_name(x)
    gn = ""
    begin
     if x['groupSet'] != nil 
        gn = x['groupSet'][1]
     elsif x[:sec_groups].instance_of? Array and x[:sec_groups][0] != nil
        gn = x[:sec_groups][0]
     elsif x['security_groups'].instance_of? Array and  x['security_groups'][0] != nil
        gn = x['security_groups'][0]['name']
     elsif x[:groups].instance_of? Array and x[:groups][0][:group_name] == nil
        gn = x[:groups][0][:group_id]
     else
        gn = x[:groups][0][:group_name]
     end
    rescue
    end
    if gn == nil
      gn = ""
    end
    return gn
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
        launch_parm = {}
        launch_parm['LaunchSpecification.ImageId']=server
        launch_parm['SpotPrice']= @launch['Spot_Price'].text
        if @launch['Maximum_Server_Count'].text != nil and @launch['Maximum_Server_Count'].text != ""
          launch_parm['InstanceCount']= @launch['Maximum_Server_Count'].text
        else
          launch_parm['InstanceCount']= "1"
        end
        if @launch['Instance_Type'].text != nil and @launch['Instance_Type'].text != ""
          launch_parm['LaunchSpecification.InstanceType']= @launch['Instance_Type'].text
        end
        if @launch['Keypair'].text != nil and @launch['Keypair'].text != ""
           launch_parm['LaunchSpecification.KeyName']= @launch['Keypair'].text
        else 
           error_message("Launch Error","Keypair not specified")
           return
        end
        g = []
        a = @launch['Security_Group'].text
        sa = (a).split(",")
        sa.each do |s|        
            g.push(s[0..s.length-1])
        end
        it = (@launch['Instance_Type'].text).downcase
        launch_parm['LaunchSpecification.SecurityGroup'] = g 
        if @launch['Availability_Zone'].text != nil and @launch['Availability_Zone'].text != ""
              launch_parm['LaunchSpecification.Placement.AvailabilityZone']= @launch['Availability_Zone'].text
        end
        launch_parm['LaunchSpecification.UserData'] = ""
        if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
              launch_parm['LaunchSpecification.UserData']= @launch['User_Data'].text
        end
        if @launch['User_Data_File'].text != nil and @launch['User_Data_File'].text != ""
            fn = @launch['User_Data_File'].text
            d = ""
            begin 
               f = File.open(fn, "r")
 	      d = f.read
               f.close
            rescue 
               puts "ERROR: could not read user data file"
               error_message("Launch Error","Could not read User Data File")
               return
            end
            if launch_parm['LaunchSpecification.UserData'] != nil and launch_parm['LaunchSpecification.UserData'] != ""
               launch_parm['LaunchSpecification.UserData']=launch_parm['LaunchSpecification.UserData']+","+d
            else
               launch_parm['LaunchSpecification.UserData']=d
            end   
        end
        if @launch['Monitoring_State'].itemCurrent?(1)
             launch_parm['LaunchSpecification.Monitoring.Enabled'] = true
        end
        if @launch['Ebs_Optimized'].itemCurrent?(0)
             launch_parm['LaunchSpecification.EbsOptimized'] = true
        end        
        if @launch['Subnet_Id'].text != nil and @launch['Subnet_Id'].text != ""
          launch_parm['LaunchSpecification.SubnetId']= @launch['Subnet_Id'].text
        end        
       # currently block mappings not supported on spot instance requests.
       # if @block_mapping != nil and @block_mapping.size>0
       #      launch_parm[:block_device_mappings] = @block_mapping
       # end        
        save
        puts "request spot instance #{server} parameters #{launch_parm}"
        item = []
       begin
           #item = ec2.request_spot_instances(launch_parm)
           item = @ec2_main.environment.servers.request_spot_instances(launch_parm)
        rescue
           error_message("Spot Instance Request Failed",$!)
           return 
        end
        req_id = item[0]['spotInstanceRequestId']
        begin 
           if @resource_tags  != nil and @resource_tags.empty == false
              item.each do |r|
                 @resource_tags.assign(req_id)
              end   
           end 
          nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
     	  if nickname_tag != nil and nickname_tag != ""
     	     name = @launch['Name'].text
             item.each do |r|
                ec2 = @ec2_main.environment.connection
                if ec2 != nil
                   r = ec2.create_tags(req_id, {nickname_tag => name})
                end 
             end    	  
     	  end           
        rescue
          error_message("Create Tags Failed",$!)
          return
       end       
    end 
 end
 
 def load(profile)
   puts "Launch.load"
   if profile!=nil and profile=="Create New Launch Profile"
      clear_panel
   elsif  @ec2_main.settings.openstack
      load_ops(profile)
   elsif @ec2_main.settings.cloudfoundry
      load_cfy(profile)
   else   
      clear_panel      
      @type = "ec2"
      @profile_type = "secgrp"
      @profile_folder = "launch"
      @properties = {}
      @frame1.show()
      @frame3.hide()
      @frame4.hide()
      @profile = profile
      @launch['Name'].text = @profile
      @launch['Name'].enabled = false
      @launch['Chef_Node'].text = @profile
      @launch['Puppet_Manifest'].text = 'init.pp'
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
        load_panel('Puppet_Manifest')
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
        load_panel('Subnet_Id')
        load_panel('Private_IP')
        load_panel('User_Data')
        load_panel('User_Data_File')
        load_monitoring_state()
        load_boolean_state('Disable_Api_Termination')
        load_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
        load_boolean_state('Ebs_Optimized')
        load_panel('Additional_Info')
        load_panel('EC2_SSH_User')
        load_panel('EC2_SSH_Private_Key')
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
           load_panel('Putty_Private_Key')
        end
        load_panel('Win_Admin_Password')
        load_panel('Local_Port')
        load_bastion
        @block_mapping.load_from_properties(@properties,"BlockMapping",@launch['Block_Devices'])
        @image_bm.load_from_properties(@properties,"Image_Bm",@launch['Image_Block_Devices']) 
        @launch_loaded = true
      else
        @launch_loaded = true
      end
      load_notes
      @ec2_main.app.forceRefresh
   end   
 end 
   
   def load_image
      puts "Launch.load_image"
       image_id = @properties['Image_Id']
       if image_id != nil and image_id != ""
         begin 
          #ec2.describe_images([image_id]).each do |r|
            r = @ec2_main.environment.images.get(image_id) 
            #puts r 
            put('Image_Manifest',r['imageLocation'])
            put('Image_Architecture',r['architecture'])
            if r['isPublic'] == true
              put('Image_Visibility',"Public")
            else
              put('Image_Visibility',"Private")
            end
            it = @launch['Instance_Type'].text
            if it == nil or it == ""
	       put('Instance_Type',"m1.small")
            end
            put('Image_Root_Device_Type',r['rootDeviceType'])
            @image_bm.load_fog(r,@launch['Image_Block_Devices'])
          #end            
         rescue
          puts "ERROR: Image not found"
          put('Image_Manifest',"*** Not Found ***")
          error_message("Error","Launch Profile: Image Id not found")
         end
      end   
   end
   
   def load_bastion
           @bastion = {}
   	   @bastion['bastion_host'] = @properties['Bastion_Host']
   	   @bastion['bastion_port'] = @properties['Bastion_Port']
   	   @bastion['bastion_user'] = @properties['Bastion_User']
   	   @bastion['bastion_ssh_key'] = @properties['Bastion_Ssh_Key']
           @bastion['bastion_putty_key'] = @properties['Bastion_Putty_Key']
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
	 @frame3.hide()
	 @frame4.hide()
         @profile_type = "image"
         @profile_folder = "image"
         if !File.exists?(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
            Dir.mkdir(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
         end    
         clear_panel
         @profile = image_id
         @properties = {}
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
           load_panel('Puppet_Manifest')
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
           load_panel('Subnet_Id')
           load_panel('Private_IP')
           load_panel('User_Data')
           load_panel('User_Data_File')
           load_monitoring_state()
           load_boolean_state('Disable_Api_Termination')
           load_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
           load_boolean_state('Ebs_Optimized')
           load_panel('Additional_Info')
           load_panel('EC2_SSH_User')
           load_panel('EC2_SSH_Private_Key')
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
              load_panel('Putty_Private_Key')
           end
           load_panel('Win_Admin_Password')
           load_panel('Local_Port')
	   load_bastion
           @launch_loaded = true
         else
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
    if  @ec2_main.settings.cloudfoundry
      clear_cfy_panel
    elsif @ec2_main.settings.openstack
      clear_ops_panel
    elsif @type == "as"  
      clear_as_panel
    else
     @type = "ec2"
     @profile = ""
     @properties = {}
     @resource_tags = nil 
     @launch['Name'].text = ""
     @launch['Name'].enabled = true
     clear('Security_Group')
     clear('Chef_Node')
     clear('Puppet_Manifest')
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
     clear('Subnet_Id')
     clear('Private_IP')
     clear('User_Data')
     clear('User_Data_File')
     clear_monitoring_state
     clear_boolean_state('Disable_Api_Termination')
     clear_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
     clear_boolean_state('Ebs_Optimized')
     clear('Additional_Info')
     clear('EC2_SSH_User')
     clear('EC2_SSH_Private_Key')
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        clear('Putty_Private_Key')
     end
     clear('Win_Admin_Password')
     clear('Local_Port')
     @bastion = {}
     @block_mapping.clear(@properties,"BlockMapping",@launch['Block_Devices'])
     @image_bm.clear(@properties,"Image_Bm",@launch['Image_Block_Devices'])
     clear_notes     
     @launch_loaded = false
    end
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
      #puts "Launch.put "+key
      @properties[key] = value
      @launch[key].text = value
   end 
   
   def save
     puts "Launch.save"
     @profile = @launch['Name'].text
     if @profile == nil or @profile == ""
        error_message("Error","No Server Name specified") 
     else
      save_launch('Image_Id')
      load_image
      load_panel('Image_Manifest')
      load_panel('Image_Architecture')
      load_panel('Image_Visibility')
      load_panel('Image_Root_Device_Type')      
      save_launch('Security_Group')
      save_launch('Chef_Node')
      save_launch('Puppet_Manifest')
      save_launch('Addressing')
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
      save_launch('Subnet_Id')
      save_launch('Private_IP')
      save_launch('User_Data')
      save_launch('User_Data_File')
      save_monitoring_state()
      save_boolean_state('Disable_Api_Termination')
      save_shutdown_behaviour('Instance_Initiated_Shutdown_Behavior')
      save_boolean_state('Ebs_Optimized')
      save_launch('Additional_Info')
      save_launch('EC2_SSH_User')
      save_launch('EC2_SSH_Private_Key')
      if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
         save_launch('Putty_Private_Key')
      end
      save_launch('Win_Admin_Password')
      save_launch('Local_Port')
      save_bastion
      @block_mapping.save(@properties,"BlockMapping")
      @image_bm.save(@properties,"Image_Bm")
      doc = ""
      @properties.each_pair do |key, value|
         if value != nil 
            #puts "#{key}=#{value}\n"
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
      @ec2_main.treeCache.refresh_launch
     end 
   end
   
   def save_bastion(bastion=nil)
            @bastion = bastion if bastion != nil 
      	    @properties['Bastion_Host'] = @bastion['bastion_host']
      	    @properties['Bastion_Port'] = @bastion['bastion_port']
      	    @properties['Bastion_User'] =  @bastion['bastion_user']
      	    @properties['Bastion_Ssh_Key'] = @bastion['bastion_ssh_key']
            @properties['Bastion_Putty_Key'] = @bastion['bastion_putty_key']
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
               clear_panel
               @ec2_main.treeCache.refresh_launch
            end
         else
            error_message("Error","No Launch Profile for "+@profile+" to delete") 
         end
      rescue 
      end
   end 
   
  def image_info
     puts "Launch.image_info" 
       img = @launch['Image_Id'].text
         r = @ec2_main.environment.images.get(img)
         put('Image_Manifest',r['imageLocation'])
         put('Image_Architecture',r['architecture'])
         if r['isPublic'] == true 
            put('Image_Visibility','public')
         else
            put('Image_Visibility','private')
         end
	 it = @launch['Instance_Type'].text
         if it == nil or it == ""
            if r['architecture'] == "x86_64"
	         put('Instance_Type',"m1.large")
	      else
	         put('Instance_Type',"m1.small")
            end 
         end
         put('Image_Root_Device_Type',r['rootDeviceType'])
         @image_bm.load_fog(r,@launch['Image_Block_Devices'])
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
      if @type == "ops"
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
   if @type == "ops"
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
