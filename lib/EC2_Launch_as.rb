class EC2_Launch


 def launch_as_Panel(item)
     load_as(item.text)
 end 
 
 def load_as(sec_grp=nil)
      puts "Launch.load_as"
      @type = "as"
      @frame1.hide()
      @frame2.hide()
      @frame3.show()
      @frame4.hide()
      @profile_type = "secgrp"
      clear_as_panel
      if sec_grp != nil and sec_grp != ""
         @profile = sec_grp
         @as_launch['Launch_Configuration_Name'].text = @profile
         @as_launch['Launch_Configuration_Name'].enabled = false
         as = @ec2_main.environment.as_connection
         if as != nil 
            i = 0
            r = as.describe_launch_configurations(@profile).each do |r|
                @as_launch['Created_Time'].text = r[:created_time]
                @as_launch['Security_Groups'].text = ""
                r[:security_groups].each do |a|
		   if @as_launch['Security_Groups'].text =""
		      @as_launch['Security_Groups'].text = a
		   else 
		      @as_launch['Security_Groups'].text = @as_launch['Security_Groups'].text + ",#{a}"
		   end 
		end 
		@as_launch['Image_Id'].text = r[:image_id]
		@as_launch['Kernel_Id'].text  = r[:kernel_id]
		@as_launch['Ramdisk_Id'].text = r[:ramdisk_id]
		@as_launch['UserData'].text = r[:user_data]
		@as_launch['Instance_Type'].text = r[:instance_type]
		@as_launch['KeyName'].text = r[:key_name]
		@as_bm.load(r,@as_launch['Block_Device_Mappings'] )
            end
         end
         @launch_loaded = true
      end   
      load_notes    
      @ec2_main.app.forceRefresh
 end
 
   def clear_as_panel
     puts "Launch.clear_as_panel" 
     @profile = ""
     @resource_tags = nil 
     as_clear('Launch_Configuration_Name')
     as_clear('Created_Time')
     as_clear('Security_Groups')
     as_clear('Image_Id')
     as_clear('Kernel_Id')
     as_clear('Ramdisk_Id')
     as_clear('UserData')
     as_clear('Instance_Type')
     as_clear('KeyName')
     @as_bm.clear_init
     @as_bm.load_table(@as_launch['Block_Device_Mappings'])
     clear_notes     
     @launch_loaded = false
   end 
  
   def as_clear(key)
      @as_launch[key].text = ""
   end  
   
   def as_put(key,value)
      @as_launch[key].text = value
   end 
   
   def as_save
      puts "Launch.as_save"
      r = {} 
	r[:launch_configuration_name] = @as_launch['Launch_Configuration_Name'].text 
	r[:created_time] = @as_launch['Created_Time'].text
	r[:security_groups] = @as_launch['Security_Groups'].text
	r[:image_id] = @as_launch['Image_Id'].text 
	if @as_launch['Kernel_Id'].text != nil and @as_launch['Kernel_Id'].text != ""
	   r[:kernel_id] = @as_launch['Kernel_Id'].text
	end
	if @as_launch['Ramdisk_Id'].text != nil and @as_launch['Ramdisk_Id'].text != ""
	   r[:ramdisk_id] = @as_launch['Ramdisk_Id'].text
	end
	if @as_launch['UserData'].text != nil and @as_launch['UserData'].text != ""
	   r[:user_data] = @as_launch['UserData'].text
	end
	r[:instance_type] = @as_launch['Instance_Type'].text 
	r[:key_name] = @as_launch['KeyName'].text
	if @as_bm.size > 0
	   r[:block_device_mappings] = @as_bm.array
	end   
      as = @ec2_main.environment.as_connection
      if as != nil 
        begin
           as.create_launch_configuration(r[:launch_configuration_name], r[:image_id], r[:instance_type] , r)
           @ec2_main.tabBook.setCurrent(5)
           @ec2_main.list.load("Launch Configurations")
           @launch_loaded = true
	  rescue
           error_message("Create Launch Configuration Failed",$!.to_s)
         end
      end  
      #save_notes
    end
   
   def as_delete
      as = @ec2_main.environment.as_connection
      if as != nil 
         i = 0
         r = as.describe_launch_configurations(@profile)
         if r != nil 
           @data[i] = r
           answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Launch Configuration "+@profile)
           if answer == MBOX_CLICKED_YES
             as.delete_launch_configuration(launch_configuration_name)
           end  
         end
      else
         error_message("Error","No DB Launch Profile for "+@profile+" to delete") 
      end    
   end 
   
   def error_message(title,message)
       FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
   end

end
