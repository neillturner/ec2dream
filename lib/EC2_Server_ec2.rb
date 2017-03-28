class EC2_Server

  def clear_panel
    if  @ec2_main.settings.openstack
      ops_clear_panel
    elsif  @ec2_main.settings.softlayer
      softlayer_clear_panel
    elsif  @ec2_main.settings.google
      google_clear_panel
    else
      @type = ""
      clear('Instance_ID')
      ENV['EC2_INSTANCE'] = ""
      clear('Security_Groups')
      clear('Tags')
      clear('Image_ID')
      clear('State')
      clear('Key_Name')
      clear('Public_DSN')
      clear('Private_DSN')
      clear('Public_IP')
      clear('Private_IP')
      set_ec2dream_hostname
      clear('Instance_Type')
      clear('Availability_Zone')
      clear('Launch_Time')
      if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
        clear('EC2_SSH_Private_Key')
      else
        clear('Putty_Private_Key')
      end
      clear('EC2_SSH_User')
      clear('Win_Admin_Password')
      clear('Local_Port')
      clear('Ami_Launch_Index')
      clear('Kernel_Id')
      clear('Ramdisk_Id')
      clear('Platform')
      clear('Subnet_Id')
      clear('Vpc_Id')
      clear('Root_Device_Type')
      clear('Root_Device_Name')
      @server['Block_Devices'].clearItems
      @block_mapping = []
      clear('Instance_Life_Cycle')
      clear('Spot_Instance_Request_Id')
      clear('Monitoring_State')
      clear('Ebs_Optimized')
      @frame1.show()
      @frame3.hide()
      @frame4.hide()
      @frame5.hide()
      @frame6.hide()
      @frame7.hide()
      @server_status = ""
      @secgrp = ""
    end
  end

  def clear(key)
    @server[key].text = ""
  end

  def load(instance_id)
    puts "load "+instance_id
    if  @ec2_main.settings.openstack
      ops_load(instance_id)
    elsif  @ec2_main.settings.softlayer
      softlayer_load(instance_id)
    elsif  @ec2_main.settings.google
      google_load(instance_id)
    else
      @type = "ec2"
      @frame1.show()
      @frame3.hide()
      @frame4.hide()
      @frame5.hide()
      @frame6.hide()
      @frame7.hide()
      @server['Instance_ID'].text = instance_id
      ENV['EC2_INSTANCE'] = instance_id
      r = @ec2_main.serverCache.instance(instance_id)
      if r != nil
        puts "#{r}"
        @server['Security_Groups'].text = @ec2_main.serverCache.instance_groups_list(instance_id)
        @secgrp = @ec2_main.serverCache.instance_groups_first(instance_id)
        if r['tagSet'].to_s != "{}"
          tags = EC2_ResourceTags.new(@ec2_main,r['tagSet'],nil)
          @server['Tags'].text = tags.show
        else
          @server['Tags'].text =  ""
        end
        @server['Image_ID'].text = r['imageId']
        @server['State'].text = r['instanceState']['name']
        @server_status = @server['State'].text
        @server['Key_Name'].text = r['keyName']
        @server['Public_DSN'].text = r['dnsName']
        @server['Private_DSN'].text = r['privateDnsName']
        @server['Public_IP'].text = r['ipAddress']
        @server['Private_IP'].text = r['privateIpAddress']
        @server['Instance_Type'].text = r['instanceType']
        @server['Availability_Zone'].text = r['placement']['availabilityZone']
        @server['Launch_Time'].text = convert_time(r['launchTime'])
        if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
          @server['EC2_SSH_Private_Key'].text = get_pk
        else
          @server['Putty_Private_Key'].text = get_ppk
        end
        @server['EC2_SSH_User'].text = ""
        instance_id = @server['Instance_ID'].text
        ssh_u = @ec2_main.launch.get('EC2_SSH_User')
        if ssh_u != nil and ssh_u != ""
          @server['EC2_SSH_User'].text = ssh_u
        else
          @server['EC2_SSH_User'].text = @ec2_main.settings.get('EC2_SSH_USER')
        end
        if @windows_admin_pw[instance_id] != nil and @windows_admin_pw[instance_id] != ""
          @server['Win_Admin_Password'].text = @windows_admin_pw[instance_id]
        else
          win_admin_psw = @ec2_main.launch.get('Win_Admin_Password')
          if  win_admin_psw != nil and  win_admin_psw != ''
            @server['Win_Admin_Password'].text = @ec2_main.launch.get('Win_Admin_Password')
          else
            @server['Win_Admin_Password'].text = ""
          end
        end
        @server['Local_Port'].text = ""
        data_temp = @ec2_main.launch.get('Local_Port')
        if data_temp != nil and data_temp != ""
          @server['Local_Port'].text = data_temp
        end
        load_bastion
        if r['monitoring']['state'] != nil and r['monitoring']['state'] == true
          @server['Monitoring_State'].text = "detailed"
        else
          @server['Monitoring_State'].text = "basic"
        end
        if r['ebsOptimized'] != nil and r['ebsOptimized'] == true
          @server['Ebs_Optimized'].text = "true"
        else
          @server['Ebs_Optimized'].text = "false"
        end
        @server['Ami_Launch_Index'].text = r['amiLaunchIndex'].to_s
        @server['Kernel_Id'].text = r['kernelId']
        @server['Ramdisk_Id'].text = r['ramdiskId']
        @server['Platform'].text = r['platform']
        @server['Subnet_Id'].text = r['subnetId']
        @server['Vpc_Id'].text = r['vpcId']
        @server['Root_Device_Type'].text = r['rootDeviceType']
        @server['Root_Device_Name'].text = r['rootDeviceName']
        @server['Block_Devices'].clearItems
        load_block_mapping(r)
        @server['Instance_Life_Cycle'].text = r['instanceLifecycle']
        @server['Spot_Instance_Request_Id'].text = r['spotInstanceRequestId']
        @server['test_kitchen_path'].text = ""  #used for iam role
        if !r["iamInstanceProfile"].empty?
          s=r["iamInstanceProfile"]["arn"]
          sa = s.split"/"
          @server['test_kitchen_path'].text = sa.last if sa.size>1
        end
      else
        puts "ERROR: No Server cache for instances #{instance_id}"
      end
      #@server['test_kitchen_path'].text=@ec2_main.settings.get('TEST_KITCHEN_PATH')
      set_ec2dream_hostname
      @ec2_main.app.forceRefresh
    end
  end

  def load_bastion
    instance_id = @server['Instance_ID'].text
    puts "Server.load_bastion #{instance_id}"
    if @bastion[instance_id] == nil
      r = {}
      r['bastion_host'] = @ec2_main.settings.get('BASTION_HOST')
      r['bastion_port'] = @ec2_main.settings.get('BASTION_PORT')
      r['bastion_user'] = @ec2_main.settings.get('BASTION_USER')
      r['bastion_password'] = @ec2_main.settings.get('BASTION_PASSWORD')
      r['bastion_ssh_key'] = @ec2_main.settings.get('BASTION_SSH_KEY')
      r['bastion_putty_key'] = @ec2_main.settings.get('BASTION_PUTTY_KEY')
      p = @ec2_main.launch.get('Bastion_Host')
      r['bastion_host'] = p if p != nil and p != ""

      p = @ec2_main.launch.get('Bastion_Port')
      r['bastion_port'] = p if p != nil and p != ""
      p = @ec2_main.launch.get('Bastion_User')
      r['bastion_user'] = p if p != nil and p != ""

      p = @ec2_main.launch.get('Bastion_Password')
      r['bastion_password'] = p if p != nil and p != ""

      p = @ec2_main.launch.get('Bastion_Ssh_Key')
      r['bastion_ssh_key'] = p if p != nil and p != ""

      p = @ec2_main.launch.get('Bastion_Putty_Key')
      r['bastion_putty_key'] = p if p != nil and p != ""

      @bastion[instance_id]=r
    end
  end

  def load_block_mapping(r)
    @block_mapping = []
    if r['blockDeviceMapping'] != nil
      r['blockDeviceMapping'].each do |m|
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
    @server['Block_Devices'].setColumnText(0, "Device Name;Volume;Attach Time;Status;Delete On Termination")
    @server['Block_Devices'].setColumnWidth(0,350)
    i = 0
    @block_mapping.each do |m|
      if m!= nil
        @server['Block_Devices'].setItemText(i, 0, "#{m['deviceName']};#{m['volumeId']};#{convert_time(m['attachTime'])};#{m['status']};#{m['deleteOnTermination']}")
        @server['Block_Devices'].setItemJustify(i, 0, FXTableItem::LEFT)
        i = i+1
      end
    end
  end

  def terminate
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.delete_server(instance)
      rescue
        error_message("Terminate Instance Failed",$!)
      end
    end
  end

  def stop_instance
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stop","Confirm Stop of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.stop_instances(instance)
      rescue
        error_message("Stop Instance Failed",$!)
      end
    end
  end

  def start_instance
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Start","Confirm Start of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.start_instances(instance)
      rescue
        error_message("Start Instance Failed",$!)
      end
    end
  end


  def monitor
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Monitoring","Confirm Detailed Monitoring of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.monitor_instances(instance)
      rescue
        puts "ERROR: monitor_instances"
      end
    end
  end

  def unMonitor
    instance = @server['Instance_ID'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stop Monitoring","Confirm Stop Detailed Monitoring Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.unmonitor_instances(instance)
      rescue
        puts "ERROR: unmonitor_instances"
      end
    end
  end
end
