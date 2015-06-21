class EC2_Launch


  def launch_as_Panel(item)
    load_as(item.text)
  end 
  def load_as(sec_grp=nil)
    puts "Launch.load_as"
    @type = "as"
    @frame1.hide()
    @frame3.show()
    @frame4.hide()
    @frame5.hide()
    @frame6.hide()
    @profile_type = "secgrp"
    clear_as_panel
    if sec_grp != nil and sec_grp != ""
      @profile = sec_grp
      @as_launch['Launch_Configuration_Name'].text = @profile
      @as_launch['Launch_Configuration_Name'].enabled = false
      i = 0
      #r = as.describe_launch_configurations(@profile).each do |r|
      begin   
        r = @ec2_main.environment.launch_configurations.get(@profile)
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
        if r[:user_data]!=nil and r[:user_data]!=""
          @as_launch['UserData'].text = Base64.decode64(r[:user_data])
        else
          @as_launch['UserData'].text = ""
        end
        @as_launch['Instance_Type'].text = r[:instance_type]
        @as_launch['KeyName'].text = r[:key_name]
        if r[:instance_monitoring] == true
          @as_launch['Instance_Monitoring'].setCurrentItem(0)
        else 
          @as_launch['Instance_Monitoring'].setCurrentItem(1)
        end
        @as_launch['Launch_Configuration_Name'].enabled = true
        @as_bm.load_fog(r,@as_launch['Block_Device_Mappings'] )
        @launch_loaded = true
      rescue 
        error_message("Loading Launch Configuration Failed",$!)   
      end
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
    @as_launch['Instance_Monitoring'].setCurrentItem(0)
    @as_bm.clear_init
    @as_bm.load_table_fog(@as_launch['Block_Device_Mappings'])
    clear_notes     
    @launch_loaded = false
    @as_launch['Launch_Configuration_Name'].enabled = true
  end 
  def as_clear(key)
    @as_launch[key].text = ""
  end  
  def as_put(key,value)
    @as_launch[key].text = value
  end 
  def as_save
    puts "Launch.as_save"
    launch_configuration_name = @as_launch['Launch_Configuration_Name'].text
    instance_type = @as_launch['Instance_Type'].text
    image_id = @as_launch['Image_Id'].text 
    r = {} 
    r['SecurityGroups'] = @as_launch['Security_Groups'].text
    if @as_launch['Kernel_Id'].text != nil and @as_launch['Kernel_Id'].text != ""
      r['KernelId'] = @as_launch['Kernel_Id'].text
    end
    if @as_launch['Ramdisk_Id'].text != nil and @as_launch['Ramdisk_Id'].text != ""
      r['RamdiskId'] = @as_launch['Ramdisk_Id'].text
    end
    if @as_launch['UserData'].text != nil and @as_launch['UserData'].text != ""
      r['UserData'] = @as_launch['UserData'].text
    end
    r['KeyName'] = @as_launch['KeyName'].text
    if @as_bm.size > 0
      r['BlockDeviceMappings'] = @as_bm.array_fog
    end 
    if @as_launch['Instance_Monitoring'].itemCurrent?(0)
      r['InstanceMonitoring.Enabled'] = true
    else
      r['InstanceMonitoring.Enabled'] = false
    end
    begin
      #as.create_launch_configuration(launch_configuration_name, image_id, instance_type , r)
      @ec2_main.environment.launch_configurations.create_launch_configuration(image_id, instance_type, launch_configuration_name,  r)
      @ec2_main.tabBook.setCurrent(0)
      @ec2_main.list.load("Launch Configurations","AutoScaling")
      @launch_loaded = true
    rescue
      error_message("Create Launch Configuration Failed",$!)
    end
    #save_notes
  end
  def as_delete
    i = 0
    #r = as.describe_launch_configurations(@profile)
    r = @ec2_main.environment.launch_configurations.get(@profile)
    if r != nil 
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Launch Configuration "+@profile)
      if answer == MBOX_CLICKED_YES
        #as.delete_launch_configuration(launch_configuration_name)
        @ec2_main.environment.launch_configurations.delete_launch_configuration(@profile)
        clear_panel
      end  
    else
      error_message("Error","No DB Launch Profile for "+@profile+" to delete") 
    end    
  end 
end
