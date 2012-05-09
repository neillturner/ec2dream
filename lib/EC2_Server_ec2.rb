 class EC2_Server
 
 def clear_panel
       @type = ""
       clear('Instance_ID')
       ENV['EC2_INSTANCE'] = ""
       clear('Security_Groups')
       clear('Chef_Node')
       clear('Tags')
       clear('Image_ID')
       clear('State')
       clear('Key_Name')
       clear('Public_DSN')
       clear('Private_DSN')
       clear('Public_IP')
       clear('Instance_Type')
       clear('Availability_Zone')
       clear('Launch_Time')
       if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
          clear('EC2_SSH_Private_Key')
       else
          clear('Putty_Private_Key')
       end
       clear('EC2_SSH_User')
       clear('Win_Admin_Password')
       clear('Ami_Launch_Index')
       clear('Kernel_Id')
       clear('Ramdisk_Id')
       clear('Platform')
       clear('Subnet_Id')
       clear('Vpc_Id')
       clear('Root_Device_Type')
       clear('Root_Device_Name')
       @server['Block_Devices'].clearItems
       @block_mapping = Array.new
       clear('Instance_Life_Cycle')
       clear('Spot_Instance_Request_Id')     
       @frame1.show()
       @frame2.hide()
       #@frame3.hide()
       @server_status = ""
       @secgrp = ""
       clear('Monitoring_State')
  #   end  
  end 
     
  def clear(key)
    @server[key].text = ""
  end 
 
  def load(instance_id)
     if @ec2_main.settings.get("EC2_PLATFORM") == "openstack" 
        ops_load(instance_id)
     else   
       puts "load "+instance_id
       @type = "ec2"
       @frame1.show()
       @frame2.hide()
       @frame3.hide()
       @server['Instance_ID'].text = instance_id
       ENV['EC2_INSTANCE'] = instance_id
       r = @ec2_main.serverCache.instance(instance_id)
       if r != nil 
    	 gp = @ec2_main.serverCache.instance_groups(instance_id)
    	 gp_list = ""
    	 gp.each do |g|
    	   if gp_list.length>0
    	    gp_list = gp_list+","+g
    	   else
    	    gp_list = g
    	    @secgrp = g
    	   end 
    	 end
    	 @server['Security_Groups'].text = gp_list
    	 if r[:tags] != nil 
    	    t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil)
    	    @server['Tags'].text = t.show
    	 else
    	    @server['Tags'].text =""
    	 end
    	 @server['Chef_Node'].text = get_chef_node
    	 @server['Image_ID'].text = r[:aws_image_id]
    	 @server['State'].text = r[:aws_state]
    	 @server_status = @server['State'].text

    	 @server['Key_Name'].text = r[:ssh_key_name]
    	 @server['Public_DSN'].text = r[:dns_name]
    	 @server['Private_DSN'].text = r[:private_dns_name]
    	 @server['Public_IP'].text = r[:public_ip]
    	 @server['Instance_Type'].text = r[:aws_instance_type]
    	 @server['Availability_Zone'].text = r[:aws_availability_zone]
    	 t = r[:aws_launch_time]
     	 tzone = @ec2_main.settings.get_system('TIMEZONE')
    	 if tzone != "UTC"
    	  tz = TZInfo::Timezone.get(tzone)
  	  t = tz.utc_to_local(DateTime.new(t[0,4].to_i,t[5,2].to_i,t[8,2].to_i,t[11,2].to_i,t[14,2].to_i,t[17,2].to_i)).to_s
         end
 	 i = t.index("T")
    	 if i != nil and i> 0
    	  t[i] = " "
    	 end
    	 i = t.index("Z")
  	 if i != nil and i> 0
  	   t[i] = " "
    	 end         
    	 @server['Launch_Time'].text = t
    	 if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
            @server['EC2_SSH_Private_Key'].text = get_pk
         else
            @server['Putty_Private_Key'].text = get_ppk
         end
         @server['EC2_SSH_User'].text = ""
         instance_id = @server['Instance_ID'].text
         ssh_u = @ec2_main.launch.get('EC2_SSH_User')
         if ssh_u != nil and ssh_u != ""
            @server['EC2_SSH_User'].text = ssh_u
         end   
     	 if @windows_admin_pw[instance_id] != nil and @windows_admin_pw[instance_id] != ""
    	   @server['Win_Admin_Password'].text = @windows_admin_pw[instance_id]
    	 else
    	   if @ec2_main.launch.get('Security_Group') ==  @server['Security_Groups'].text
    	      @server['Win_Admin_Password'].text = @ec2_main.launch.get('Win_Admin_Password')
    	   else
    	       @server['Win_Admin_Password'].text = ""
    	   end
    	 end
    	 @server['Monitoring_State'].text = r[:aws_monitoring_state]
         @server['Ami_Launch_Index'].text = r[:ami_launch_index]
         @server['Kernel_Id'].text = r[:aws_kernel_id]
         @server['Ramdisk_Id'].text = r[:aws_ramdisk_id]
         @server['Platform'].text = r[:aws_platform]
         @server['Subnet_Id'].text = r[:subnet_id]
         @server['Vpc_Id'].text = r[:vpc_id]
         @server['Root_Device_Type'].text = r[:root_device_type]
         @server['Root_Device_Name'].text = r[:root_device_name]
         @server['Block_Devices'].clearItems
         load_block_mapping(r)
         @server['Instance_Life_Cycle'].text = r[:instance_life_cycle]
         @server['Spot_Instance_Request_Id'].text = r[:spot_instance_request_id]
     	 @ec2_main.app.forceRefresh
       end	 
     end	 
  end 
 
  def load_block_mapping(r)
       @block_mapping = Array.new 
       if r[:block_device_mappings] != nil
          r[:block_device_mappings].each do |m|
            if m!= nil      
               @block_mapping.push(m)
 	    end
 	  end 
       end
       load_block_mapping_table      
  end

  def load_block_mapping_table
          @server['Block_Devices'].clearItems
          @server['Block_Devices'].rowHeaderWidth = 0	
          @server['Block_Devices'].setTableSize(@block_mapping.size, 1)
          @server['Block_Devices'].setColumnText(0, "Device Name;Volume;Attach Time;Status;Size;Delete On Termination") 
          @server['Block_Devices'].setColumnWidth(0,350)
          i = 0
          @block_mapping.each do |m|
            if m!= nil 
               @server['Block_Devices'].setItemText(i, 0, "#{m[:device_name]};#{m[:ebs_volume_id]};#{m[:ebs_attach_time]};#{m[:ebs_status]};#{m[:ebs_volume_size]};#{m[:ebs_delete_on_termination]}")
               @server['Block_Devices'].setItemJustify(i, 0, FXTableItem::LEFT)
               i = i+1
    	    end 
          end   
  end
 
 def terminate
   instance = @server['Instance_ID'].text
   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
   if answer == MBOX_CLICKED_YES
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
       begin
          r = ec2.terminate_instances([instance])
       rescue
          error_message("Terminate Instance Failed",$!.to_s)
       end      
    end
   end 
 end
 
 def stop_instance
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stop","Confirm Stop of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
       begin
          r = ec2.stop_instances(instance)
       rescue
          error_message("Stop Instance Failed",$!.to_s)
       end       
     end
    end 
 end
 
 def start_instance
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Start","Confirm Start of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
       begin 
          r = ec2.start_instances(instance)
       rescue
          error_message("Start Instance Failed",$!.to_s)
       end          
     end
    end 
 end
 
 
 def monitor
  platform = @ec2_main.settings.get("EC2_PLATFORM")
  if platform == "amazon"
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Monitoring","Confirm Monitoring of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
       r = ec2.monitor_instances([instance])
     end
    end
  end  
 end 
 
 def unMonitor
   platform = @ec2_main.settings.get("EC2_PLATFORM")
   if platform == "amazon"
     instance = @server['Instance_ID'].text
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stop Monitoring","Confirm Stop Monitoring Server Instance "+instance)
     if answer == MBOX_CLICKED_YES
      ec2 = @ec2_main.environment.connection
      if ec2 != nil
        r = ec2.unmonitor_instances([instance])
      end
     end
   end
 end
 
 end