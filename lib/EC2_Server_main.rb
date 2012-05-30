class EC2_Server

  def initialize(owner)
        @ec2_main = owner
        @securityGrps = Array.new
        @secgrp =""
        @type = ""
        @windows_admin_pw = {}
        @ec2_ssh_private_key = {}
        @ec2_chef_node = {}
        @putty_private_key = {}
        @mysql_admin_pw = {}
        @server_status = ""
        @server = {}
        @ops_server = {}
        @rds_server = {}
        @block_mapping = Array.new
        @flavor = {}
        @image = {}
        @curr_row = nil
        @magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
        tab2 = FXTabItem.new(@ec2_main.tabBook, " Server ")
        @page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        page1a = FXHorizontalFrame.new(@page1,LAYOUT_FILL_X, :padding => 0)
	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Server Status Refresh"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	    puts "server.refresh.connect"
	    if @type == "ec2"  or @type == "ops" 
	       s = @server['Instance_ID'].text
	       if s != nil and s != ""
	          @ec2_main.serverCache.refresh(s)	    
	    	  load(s)
	       end
	    end
	    if @type == "rds" 
	       s = @rds_server['DBInstanceId'].text
	       if s != nil and s != ""
	          @ec2_main.serverCache.rds_refresh(s)	    
	    	  load_rds(s)
	       end
	    end	
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	@putty_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@monitor = @ec2_main.makeIcon("monitor.png")
	@monitor.create
	@putty_button.icon = @monitor
        @putty_button.tipText = " SSH "
	@putty_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "ec2"
               run_ssh
            end 
            if @type == "ops"
               ops_run_ssh
            end
            if @type == "rds"
               run_mysql_admin
            end
	end
	@putty_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_server_loaded(sender)
	    if loaded
	       @putty_button.tipText = " SSH "
	    end
	    if rds_loaded
	       @putty_button.tipText = " MySQL Administrator "
	    end	    
	end
	@winscp_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@put = @ec2_main.makeIcon("application_put.png")
	@put.create
	@reboot = @ec2_main.makeIcon("arrow_red_redo.png")
	@reboot.create
	@winscp_button.icon = @put
	@winscp_button.tipText = "  SCP  "
	@winscp_button.connect(SEL_COMMAND) do |sender, sel, data|
	   puts "server.serverWinscp.connect"
	   if @type == "ec2" or @type == "ops"
              run_scp
           elsif @type == "rds"
              reboot_rds(@rds_server['DBInstanceId'].text)
           end
	end
	@winscp_button.connect(SEL_UPDATE) do |sender, sel, data|
           if loaded
	      sender.enabled = true
              @winscp_button.icon = @put
	      @winscp_button.tipText = "  SCP  "
	   elsif rds_loaded
	      sender.enabled = true
	      @winscp_button.icon = @reboot
	      @winscp_button.tipText = " Reboot  "
  	   else
	      sender.enabled = false
	   end 
	end		
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
	   @remote_desktop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	   @desktop = @ec2_main.makeIcon("desktop_empty.png")
	   @desktop.create
	   @remote_desktop_button.icon = @desktop
	   @remote_desktop_button.tipText = " Remote Desktop "
	   @remote_desktop_button.connect(SEL_COMMAND) do |sender, sel, data|
	      puts "server.serverRemote_Desktop.connect"
              run_remote_desktop    
	   end
	   @remote_desktop_button.connect(SEL_UPDATE) do |sender, sel, data|
		enable_if_ec2_server_loaded(sender)
	   end
	end
	@terminate_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@disconnect = @ec2_main.makeIcon("disconnect.png")
	@disconnect.create
	@terminate_button.icon = @disconnect
	@terminate_button.tipText = " Terminate Instance "
	@terminate_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "rds"
	       deletedialog = RDS_InstanceDeleteDialog.new(@ec2_main,@rds_server['DBInstanceId'].text)
               deletedialog.execute
	    elsif @type == "ec2"  
	       terminate
	    elsif @type == "ops" 
	       ops_terminate
	    end  
	end
	@terminate_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = false
	    if @type == "ec2" and (@server_status == "running" or @server_status == "stopped"or @server_status == "pending") 
	       sender.enabled = true
	    end   
	    if @type == "ops" and (@server_status == "ACTIVE"  or @server_status == "BUILD")
	       sender.enabled = true
	    end 	    
	    if @type == "rds"
	       enable_if_rds_server_loaded_or_pending(sender)
	    end   
	end
	@log_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@log = @ec2_main.makeIcon("script.png")
	@log.create
	@modify = @ec2_main.makeIcon("application_edit.png")
	@modify.create	
	@log_button.icon = @log
	@log_button.tipText = " Console Output "
	@log_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type == "ec2"
	      s = currentInstance()
	      g =instance_group(s)	   
	      consoledialog = EC2_System_ConsoleDialog.new(@ec2_main,g,s)
              consoledialog.execute
           elsif @type == "rds"
 	      modifydialog = RDS_InstanceModifyDialog.new(@ec2_main,@rds_server['DBInstanceId'].text)
              modifydialog.execute             
           end   	
 	end
	@log_button.connect(SEL_UPDATE) do |sender, sel, data|
           if loaded or  @server_status == "pending" and @type == "ec2"
              @log_button.icon = @log
	      @log_button.tipText = " Console Output "
              sender.enabled = true
           elsif rds_loaded
              @log_button.icon = @modify
	      @log_button.tipText = " Modify DB Instance "
              sender.enabled = true
           else
              sender.enabled = false
           end      
	end
	@mon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@mon = @ec2_main.makeIcon("dashboard.png")
	@mon.create
	@mon_button.icon = @mon
	@mon_button.tipText = " Monitor Instance "
	@mon_button.connect(SEL_COMMAND) do |sender, sel, data|
	    monitor
 	end
	@mon_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_ec2_server_loaded_or_pending(sender) 
	end
	@unmon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@unmon = @ec2_main.makeIcon("dashboard_stop.png")
	@unmon.create
	@unmon_button.icon = @unmon
	@unmon_button.tipText = " Stop Monitoring Instance "
	@unmon_button.connect(SEL_COMMAND) do |sender, sel, data|
	    unMonitor
 	end
	@unmon_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_ec2_server_loaded_or_pending(sender) 
	end
	@start_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@start_icon = @ec2_main.makeIcon("arrow_right.png")
	@start_icon.create
	@start_button.icon = @start_icon
	@start_button.tipText = " Start Instance "
	@start_button.connect(SEL_COMMAND) do |sender, sel, data|
	    start_instance
 	end
	@start_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_ebs_ec2_server_loaded(sender) 
	end
	@stop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@stop_icon = @ec2_main.makeIcon("cancel.png")
	@stop_icon.create
	@stop_button.icon = @stop_icon
	@stop_button.tipText = " Stop Instance "
	@stop_button.connect(SEL_COMMAND) do |sender, sel, data|
	    stop_instance
 	end
	@stop_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_ebs_ec2_server_loaded(sender) 
	end 	
	@create_image_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create_image_icon = @ec2_main.makeIcon("package.png")
	@create_image_icon.create
	@create_image_button.icon = @create_image_icon
	@create_image_button.tipText = " Create Image "
	@create_image_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type == "ec2"
	      if @server['Root_Device_Type'].text == "ebs"
	         s = currentInstance()
                 today = DateTime.now
                 g =instance_group(s)
                 n=g.gsub("_","-")+ "-" + today.strftime("%Y%m%d")	      
	         dialog = EC2_ImageCreateDialog.new(@ec2_main,s,n)
                 dialog.execute
                 if dialog.created
                    image_id = dialog.image_id
                    FXMessageBox.information(page1,MBOX_OK,"EBS Image #{image_id} created")    
                 end
              else 
                 dialog = EC2_ImageRegisterDialog.new(@ec2_main)
                 dialog.execute         
              end   
           end 
 	end 	
	@create_image_button.connect(SEL_UPDATE) do |sender, sel, data|
	    if @type == "ec2" and @server_status != "terminated"
	       sender.enabled = true
	     else
	       sender.enabled = false
	    end 	
	end
	@chef_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@chef_icon = @ec2_main.makeIcon("chef.png")
	@chef_icon.create
	@chef_button.icon = @chef_icon
	@chef_button.tipText = " Run Chef Solo Roles and Recipes "
	@chef_button.connect(SEL_COMMAND) do |sender, sel, data|
           run_chef
	end
	@chef_button.connect(SEL_UPDATE) do |sender, sel, data|
           enable_if_ec2_server_loaded(sender)	
	end
        @graphs = FXComboBox.new(page1a, 15,
	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
	@graphs.numVisible = 12      
	@graphs.appendItem("")	
	@graphs.appendItem("Last Hour")
	@graphs.appendItem("Last 3 Hours")
	@graphs.appendItem("Last 12 Hours")
	@graphs.appendItem("Today")
	@graphs.appendItem("Yesterday")
	@graphs.appendItem("Last Fortnight")
	d = Date.today()
	d = d-2
	i = 0
	while i < 12  
	 @graphs.appendItem(d.strftime("%a %b %d %Y"))
	 d = d-1
	 i = i+1
	end 
	@graphs.connect(SEL_COMMAND) do |sender, sel, data|
	   if @ec2_main.settings.get("EC2_PLATFORM") == "amazon"
		mondialog = EC2_MonitorDialog.new(@ec2_main,@server['Instance_ID'].text,@secgrp,data)
	       	mondialog.execute
	   end    	
        end
        FXLabel.new(page1a, "Graphs",:opts => LAYOUT_RIGHT )
  	
	@frame1 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(@frame1, "Security Groups" )
        @frame1s = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@server['Security_Groups'] = FXTextField.new(@frame1s, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1s, "" )
 	FXLabel.new(@frame1s, "Chef Node" )
 	@server['Chef_Node'] = FXTextField.new(@frame1s, 21, nil, 0, :opts => FRAME_SUNKEN)
	@server['Chef_Node'].connect(SEL_COMMAND) do
           instance_id = @server['Instance_ID'].text
           @ec2_chef_node[instance_id] = @server['Chef_Node'].text
           @ec2_main.launch.put('Chef_Node',@server['Chef_Node'].text) 
    	   @ec2_main.launch.save		   
	end 	
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Instance ID" )
 	@server['Instance_ID'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	@server['Instance_ID_Button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
	@view = @ec2_main.makeIcon("application_view_icons.png")
	@view.create
	@server['Instance_ID_Button'].icon = @view
	@server['Instance_ID_Button'].tipText = "  Modify Instance Attributes  "
	@server['Instance_ID_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	    @curr_item = @server['Instance_ID'].text
            if @curr_item == nil or @curr_item == ""
               error_message("No Instance Id","No Instance Id to modify attributes")
            else
               dialog = EC2_InstanceModifyDialog.new(@ec2_main,@server['Instance_ID'].text)
               dialog.execute
            end
	end
 	FXLabel.new(@frame1, "Tags" )
 	@server['Tags'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Image ID" )
 	@server['Image_ID'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	@frame1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
	@server['attributes_button'] = FXButton.new(@frame1a, " ",:opts => BUTTON_TOOLBAR)
	@server['attributes_button'].icon = @view
	@server['attributes_button'].tipText = "  Image Attributes  "
	@server['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
	    @curr_item = @server['Image_ID'].text
            if @curr_item == nil or @curr_item == ""
               error_message("No Image Id","No Image Id specified to display attributes")
            else
               imagedialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
               imagedialog.execute
            end
	end
	@server['market_button'] = FXButton.new(@frame1a, " ",:opts => BUTTON_TOOLBAR)
	@market_icon = @ec2_main.makeIcon("cloudmarket.png")
	@market_icon.create
	@server['market_button'].icon = @market_icon
	@server['market_button'].tipText = "  CloudMarket Info  "
	@server['market_button'].connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.environment.browser("http://thecloudmarket.com/image/#{@server['Image_ID'].text}")
	end
 	FXLabel.new(@frame1, "State" )
 	@server['State'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	@server['State'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Public DSN" )
 	@server['Public_DSN'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Private DSN" )
 	@server['Private_DSN'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Elastic IP" )
 	@server['Public_IP'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Instance Type" )
 	@frame1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@server['Instance_Type'] = FXTextField.new(@frame1b, 20, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1b, "         Availability Zone")
 	@server['Availability_Zone'] = FXTextField.new(@frame1b, 20, nil, 0, :opts => TEXTFIELD_READONLY) 	
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Key Name" )
	@frame1c = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@server['Key_Name'] = FXTextField.new(@frame1c, 20, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1c, "         Monitoring State" )
	@server['Monitoring_State'] = FXTextField.new(@frame1c, 20, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame1, "" )    	 	
	FXLabel.new(@frame1, "Launch Time" )
	@server['Launch_Time'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame1, "" )

	if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
	   FXLabel.new(@frame1, "EC2 SSH Private Key" )
 	   @server['EC2_SSH_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @server['EC2_SSH_Private_Key'].connect(SEL_COMMAND) do
               instance_id = @server['Instance_ID'].text
               @ec2_ssh_private_key[instance_id] = @server['EC2_SSH_Private_Key'].text
               @ec2_main.launch.put('EC2_SSH_Private_Key',@server['EC2_SSH_Private_Key'].text) 
    	       @ec2_main.launch.save		   
	   end
	   @server['EC2_SSH_Private_Key_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	   @server['EC2_SSH_Private_Key_Button'].icon = @magnifier
	   @server['EC2_SSH_Private_Key_Button'].tipText = "Browse..."
	   @server['EC2_SSH_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame1, "Select pem file")
	      dialog.patternList = [
	          "Pem Files (*.pem)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @server['EC2_SSH_Private_Key'].text = dialog.filename
                 instance_id = @server['Instance_ID'].text
                 @ec2_ssh_private_key[instance_id] = @server['EC2_SSH_Private_Key'].text
                 @ec2_main.launch.put('EC2_SSH_Private_Key',@server['EC2_SSH_Private_Key'].text) 
    	 	 @ec2_main.launch.save	         
	      end
	   end	   
        else
	   FXLabel.new(@frame1, "Putty Private Key" )        
 	   @server['Putty_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @server['Putty_Private_Key'].connect(SEL_COMMAND) do
               instance_id = @server['Instance_ID'].text
               @putty_private_key[instance_id] = @server['Putty_Private_Key'].text
               @ec2_main.launch.put('Putty_Private_Key',@server['Putty_Private_Key'].text) 
    	       @ec2_main.launch.save		   
	   end
	   @server['Putty_Private_Key_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	   @server['Putty_Private_Key_Button'].icon = @magnifier
	   @server['Putty_Private_Key_Button'].tipText = "Browse..."
	   @server['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame1, "Select ppk file")
	      dialog.patternList = [
	          "Pem Files (*.ppk)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @server['Putty_Private_Key'].text = dialog.filename
                 instance_id = @server['Instance_ID'].text
                 @putty_private_key[instance_id] = @server['Putty_Private_Key'].text
                 @ec2_main.launch.put('Putty_Private_Key',@server['Putty_Private_Key'].text) 
    	         @ec2_main.launch.save	         
	      end
	   end       
        end
	FXLabel.new(@frame1, "EC2 SSH/Windows User" )
	@server['EC2_SSH_User'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        @server['EC2_SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.launch.put('EC2_SSH_User',data) 
    	   @ec2_main.launch.save        
	end
	FXLabel.new(@frame1, "" )        
	FXLabel.new(@frame1, "Win Admin Password" )
	@server['Win_Admin_Password'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	@server['Win_Admin_Password_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	@key = @ec2_main.makeIcon("key.png")
	@key.create
	@server['Win_Admin_Password_Button'].icon = @key
	@server['Win_Admin_Password_Button'].tipText = "Depcrypt Windows Admin Password"
	@server['Win_Admin_Password_Button'].connect(SEL_COMMAND) do
	   if loaded
	     pk = get_pk
	     if pk != nil and pk != ""
	       if File.exists?(pk)
		 puts "loading "+pk
		 f = File.open(pk, "r")
	         pk_text = f.read
	         f.close
  	         ec2 = @ec2_main.environment.connection
                 if ec2 != nil
	           begin
	             pw = ec2.get_initial_password(@server['Instance_ID'], pk_text)
                     @server['Win_Admin_Password'].text = pw
                     instance_id = @server['Instance_ID'].text
                     @windows_admin_pw[instance_id] = pw
                     @ec2_main.launch.put('Win_Admin_Password',pw) 
    	 	     @ec2_main.launch.save
	           rescue
	             error_message("Error - Unable to get Windows password", $!.to_s) 
	           end
                 end
               else 
	         error_message("Error","EC2 SSH Private Key Specified in launch profile does not exist")   
               end
	     else
               error_message("Error","No EC2 SSH Private Key Specified in launch profile")
             end                
           else
             error_message("Error","Server not running. Press refresh")
           end 
        end
	FXLabel.new(@frame1, "AMI Launch Index" )    	 
        @server['Ami_Launch_Index'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Kernel Id" )
	@frame1f = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
        @server['Kernel_Id'] = FXTextField.new(@frame1f, 20, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame1f, "                 Ramdisk Id" )        
        @server['Ramdisk_Id'] = FXTextField.new(@frame1f, 20, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "Platform" )
        @server['Platform'] = FXTextField.new(@frame1, 25, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Subnet Id" )
	@frame1e = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
        @server['Subnet_Id'] = FXTextField.new(@frame1e, 25, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame1e, "    VPC Id" )        
        @server['Vpc_Id'] = FXTextField.new(@frame1e, 25, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )        
	FXLabel.new(@frame1, "Root Device Type" )
	@frame1d = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
        @server['Root_Device_Type'] = FXTextField.new(@frame1d, 20, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame1d, "     Root Device Name" )        
        @server['Root_Device_Name'] = FXTextField.new(@frame1d, 20, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "Block Devices (EBS)")
	
	@server['Block_Devices'] = FXTable.new(@frame1,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@server['Block_Devices'].connect(SEL_COMMAND) do |sender, sel, which|
	   @curr_row = which.row
	   @server['Block_Devices'].selectRow(@curr_row)
	end
        @server['Block_Devices_Button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
	@camera = @ec2_main.makeIcon("camera.png")
	@camera.create
	@server['Block_Devices_Button'].icon = @camera
	@server['Block_Devices_Button'].tipText = "  Snapshot Block Device  "
	@server['Block_Devices_Button'].connect(SEL_COMMAND) do |sender, sel, data|
            if @curr_row == nil or  @server['Block_Devices'].anythingSelected? == false
               error_message("No Block Device","No Block Device selected to snapshot")
            else
              row = @server['Block_Devices'].getItemText(@curr_row,0)
     	      sa = (row).split";"
              if sa.size>1
                 dialog = EC2_SnapCreateDialog.new(@ec2_main,sa[1])
                 dialog.execute
              end
              
            end  
        end
        @server['Block_Devices_Button'].connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end	
	FXLabel.new(@frame1, "Instance Life Cycle" )        
        @server['Instance_Life_Cycle'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )        
	FXLabel.new(@frame1, "Spot Instance Request Id" )        
        @server['Spot_Instance_Request_Id'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame1, "" )        
        #
      	# rds server frame
      	#
      	@frame2 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
      	@frame2.hide()
 	FXLabel.new(@frame2, "DBSecurity Groups" )
 	@rds_server['DBSecurity_Groups'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBInstance Id" )
 	@rds_server['DBInstanceId'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBName" )
 	@rds_server['DBName'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
        FXLabel.new(@frame2, "DBInstance Class" )
 	@rds_server['DBInstanceClass'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Allocated Storage" )
 	@rds_server['AllocatedStorage'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
        FXLabel.new(@frame2, "Availability Zone")
 	@rds_server['AvailabilityZone'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame2, "" )
        FXLabel.new(@frame2, "Multi AZ")
 	@rds_server['MultiAZ'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Engine" )
 	@rds_server['Engine'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Engine Version" )
 	@rds_server['EngineVersion'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Master Username" )
 	@rds_server['MasterUsername'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Master User Password" )
	@rds_server['MasterUserPassword'] = FXTextField.new(@frame2, 50, nil, 0, :opts => FRAME_SUNKEN )
	FXLabel.new(@frame2, "" )
	@rds_server['MasterUserPassword'].connect(SEL_COMMAND) do
	   puts @rds_server['DBInstanceId'].text
	   puts @rds_server['MasterUserPassword'].text
	   if @rds_server['DBInstanceId'].text != nil and @rds_server['DBInstanceId'].text != ""
	      @mysql_admin_pw[@rds_server['DBInstanceId'].text] = @rds_server['MasterUserPassword'].text
	   end   
        end  	
 	FXLabel.new(@frame2, "DBInstance  Status" )
 	@rds_server['DBInstance_Status'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	@rds_server['DBInstance_Status'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
        FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Instance Create Time" )
 	@rds_server['Instance_Create_Time'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Latest Restorable Time" )
 	@rds_server['Latest_Restorable_Time'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
        FXLabel.new(@frame2, "" )        
 	FXLabel.new(@frame2, "Preferred Maint Window" )
 	@rds_server['PreferredMaintenanceWindow'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBParameter Group Name")
 	@rds_server['DBParameterGroupName'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Backup Retention Period")
 	@rds_server['BackupRetentionPeriod'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "PreferredBackupWindow" )
	@rds_server['PreferredBackupWindow'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Port" )
	@rds_server['Port'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )	
	FXLabel.new(@frame2, "Address" )
	@rds_server['Address'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Auto Minor Version Upgrade")
 	@rds_server['AutoMinorVersionUpgrade'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Read Replica Source DBInst Id")
 	@rds_server['ReadReplicaSourceDBInstanceId'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Read Replica  DBInstance Ids")
 	@rds_server['ReadReplicaDBInstanceIds'] = FXTextField.new(@frame2, 50, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame2, "" )
	#
	# ops frame
	#
	@frame3 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
	@frame3.hide()
 	FXLabel.new(@frame3, "Name" )
        @frame3s = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
 	@ops_server['Name'] = FXTextField.new(@frame3s, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3s, "" )
 	FXLabel.new(@frame3s, "Chef Node" )
 	@ops_server['Chef_Node'] = FXTextField.new(@frame3s, 21, nil, 0, :opts => FRAME_SUNKEN)
	@ops_server['Chef_Node'].connect(SEL_COMMAND) do
           instance_id = @ops_server['Instance_ID'].text
           @ec2_chef_node[instance_id] = @ops_server['Chef_Node'].text
           @ec2_main.launch.put('Chef_Node',@ops_server['Chef_Node'].text) 
    	   @ec2_main.launch.save		   
	end
	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "Security Groups" )
	@ops_server['Security_Groups'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Instance ID" )
 	@ops_server['Instance_ID'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Image ID" )
 	@ops_server['Image_ID'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
	@ops_server['attributes_button'] = FXButton.new(@frame3, " ",:opts => BUTTON_TOOLBAR)
	@ops_server['attributes_button'].icon = @view
	@ops_server['attributes_button'].tipText = "  Image Attributes  "
	@ops_server['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
	    @curr_item = @ops_server['Image_ID'].text
            if @curr_item == nil or @curr_item == ""
               error_message("No Image Id","No Image Id specified to display attributes")
            else
               imagedialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
               imagedialog.execute
            end
	end
	FXLabel.new(@frame3, "Image Name" )
	@ops_server['Image_Name'] = FXTextField.new(@frame3, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "State" )
 	@ops_server['State'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	@ops_server['State'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "IP Addr" )
        @frame3b = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
 	@ops_server['Addr'] = FXTextField.new(@frame3b, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3b, "" )
 	FXLabel.new(@frame3b, "Addr Type" )
 	@ops_server['Addr_Type'] = FXTextField.new(@frame3b, 20, nil, 0, :opts => TEXTFIELD_READONLY) 	
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Progress" )
 	@ops_server['Progress'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "Personality" )
 	@ops_server['Personality'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Flavor" )
 	@ops_server['Flavor'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Availability Zone")
 	@ops_server['Availability_Zone'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY) 	
	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "Key Name" )
 	@ops_server['Key_Name'] = FXTextField.new(@frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame3, "" )
        if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
	   FXLabel.new(@frame3,"SSH Private Key" )
 	   @ops_server['SSH_Private_Key'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @ops_server['SSH_Private_Key'].connect(SEL_COMMAND) do
               instance_id = @ops_server['Instance_ID'].text
               @ec2_ssh_private_key[instance_id] = @ops_server['SSH_Private_Key'].text
               @ec2_main.launch.ops_put('SSH_Private_Key',@ops_server['SSH_Private_Key'].text) 
    	       @ec2_main.launch.ops_save		   
	   end
	   @ops_server['SSH_Private_Key_Button'] = FXButton.new(@frame3, "", :opts => BUTTON_TOOLBAR)
	   @ops_server['SSH_Private_Key_Button'].icon = @magnifier
	   @ops_server['SSH_Private_Key_Button'].tipText = "Browse..."
	   @ops_server['SSH_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame3, "Select pem file")
	      dialog.patternList = [
	          "Pem Files (*.pem)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @ops_server['SSH_Private_Key'].text = dialog.filename
                 instance_id = @ops_server['Instance_ID'].text
                 @ec2_ssh_private_key[instance_id] = @ops_server['SSH_Private_Key'].text
                 @ec2_main.launch.ops_put('SSH_Private_Key',@ops_server['SSH_Private_Key'].text) 
    	 	 @ec2_main.launch.save	         
	      end
	   end	   
        else
	   FXLabel.new(@frame3, "Putty Private Key" )        
 	   @ops_server['Putty_Private_Key'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @ops_server['Putty_Private_Key'].connect(SEL_COMMAND) do
               instance_id = @ops_server['Instance_ID'].text
               @putty_private_key[instance_id] = @ops_server['Putty_Private_Key'].text
               @ec2_main.launch.ops_put('Putty_Private_Key',@ops_server['Putty_Private_Key'].text) 
    	       @ec2_main.launch.save		   
	   end
	   @ops_server['Putty_Private_Key_Button'] = FXButton.new(@frame3, "", :opts => BUTTON_TOOLBAR)
	   @ops_server['Putty_Private_Key_Button'].icon = @magnifier
	   @ops_server['Putty_Private_Key_Button'].tipText = "Browse..."
	   @ops_server['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame3, "Select ppk file")
	      dialog.patternList = [
	          "Pem Files (*.ppk)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @ops_server['Putty_Private_Key'].text = dialog.filename
                 instance_id = @ops_server['Instance_ID'].text
                 @putty_private_key[instance_id] = @ops_server['Putty_Private_Key'].text
                 @ec2_main.launch.ops_put('Putty_Private_Key',@ops_server['Putty_Private_Key'].text) 
    	         @ec2_main.launch.save	         
	      end
	   end       
        end
	FXLabel.new(@frame3, "SSH User" )
	@ops_server['SSH_User'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        @ops_server['SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.launch.ops_put('SSH_User',data) 
    	   @ec2_main.launch.save        
	end
	FXLabel.new(@frame3, "" )  

  end 
  
  def loaded
     if @type == "ec2" and @server_status == "running" 
      return true
     elsif @type == "ops" and @server_status == "ACTIVE"
     
        return true
     else   
        return false 
     end 
  end
  

  def run_scp
           s = @server['Public_IP'].text
           if s == nil or s == ""
	      s = currentServer
	   end
	   user = @ec2_main.launch.get("EC2_SSH_User")
	   if user == nil or user == ""
	      user = "root"
	   end	   
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
	      pk = get_ppk
	      if pk != nil and pk != ""
	         c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/winscp/winscp.exe\" sftp://"+user+"@"+s+"  /privatekey="+"\""+pk+"\""
	         puts c
	         system(c)
	      else
	         error_message("Error","No Putty Private Key in Settings")
              end
           else
	      pk = get_pk
 	      if pk != nil and pk != ""
                 c = "\nTo copy files to server "+@secgrp+"/"+@server['Instance_ID'].text+" use comand\n"
                 c =  c+" scp -i "+pk+" <source> "+user+"@"+s+"\n\n"
                 c =  c+"To copy files from server "+@secgrp+"/"+@server['Instance_ID'].text+" use comand\n"
		 c =  c+" scp -i "+pk+" "+user+"@"+s+" <source>\n" 
		 csvdialog = EC2_CSVDialog.new(@ec2_main,c,"SCP Command")
                 csvdialog.execute
	      else
	         error_message("Error","No SSH Private Key in Settings")
              end           
           end
  end
 
  def run_ssh
            s = @server['Public_IP'].text
            if s == nil or s == ""
	       s = currentServer
	    end
 	    user = @ec2_main.launch.get("EC2_SSH_User")
 	    if @type == "ops" 
 	       user = @ec2_main.launch.ops_get("SSH_User")
 	    end  	    
	    if user == nil or user == ""
	       user = "root"
	    end
            if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
	       pk = get_ppk
	       if pk != nil and pk != ""
	          c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -i "+"\""+pk+"\""+" -l "+user
	          puts c
	          system(c)
	       else
	          error_message("Error","No Putty Private Key in Settings")
               end
            else
	       pk = get_pk
	       if pk != nil and pk != ""
	          te = "xterm"
                  if @ec2_main.settings.get_system('TERMINAL_EMULATOR') != nil and @ec2_main.settings.get_system('TERMINAL_EMULATOR') != ""
	             te = @ec2_main.settings.get_system('TERMINAL_EMULATOR')
	          end 
	          if RUBY_PLATFORM.index("linux") != nil
	             if te == "xterm"
                         c = "xterm -hold -e ssh -i "+pk+" "+s+" -l "+user+" &"
                     else 
                         c = te+ " -x ssh -i "+pk+" "+s+" -l "+user+" &"
                     end
	          else
		     if te == "xterm"
                         c = "xterm -e ssh -i "+pk+" "+s+" -l "+user+" &"
                     else 
                         c = te+ " -x ssh -i "+pk+" "+s+" -l "+user+" &"
                     end	          
	          end	          
	          puts c
	          system(c)
	       else
	          error_message("Error","No SSH Private Key in Settings")
               end
            end
  end 
  

  def run_remote_desktop
              s = @server['Public_IP'].text
              if s == nil or s == ""
	         s = currentServer
	      end
	      user = @ec2_main.launch.get("EC2_SSH_User")
 	      if @type == "ops" 
 	         user = @ec2_main.launch.ops_get("SSH_User")
 	      end  	    
	      if user == nil or user == ""
	         user = "Administrator"
	      end     
	      pk = get_pk
	      if pk != nil and pk != ""
	         pw = @server['Win_Admin_Password'].text
	         if pw != nil and pw != ""
	           c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" #{s} 3389 #{user} #{s} #{pw} 0 1 0"
	           puts c
	           system(c)
	         else
	           error_message("Error","No Win Admin Password")
                 end		       
	      else
	         error_message("Error","No EC2 SSH Private Key")
              end
  end 
  
  def get_chef_node
      instance_id = @server['Instance_ID'].text
      if @ec2_chef_node[instance_id] != nil and @ec2_chef_node[instance_id] != ""
  	cn =  @ec2_chef_node[instance_id]
      else  
        cn = @ec2_main.launch.get('Chef_Node')
        if cn == nil or cn == ""
         cn = @secgrp
        end
      end   
      return cn
  end   
  
  def get_pk
    instance_id = @server['Instance_ID'].text
    if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
	pk =  @ec2_ssh_private_key[instance_id]
    else  
      pk = @ec2_main.launch.get('EC2_SSH_Private_Key')
      if pk == nil or pk == ""
       pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
      end
    end   
    return pk
  end   
  
  def get_ppk
    instance_id = @server['Instance_ID'].text
    if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
	pk =  @putty_private_key[instance_id]
    else	  
       pk = @ec2_main.launch.get('Putty_Private_Key')
       if pk == nil or pk == ""
          pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
       end
    end   
    return pk
  end  
    
  def currentInstance
      if @type == "ec2"
          return @server['Instance_ID'].text
      elsif @type == "ops"
          return @ops_server['Instance_ID'].text
      else
          return ""
      end       
  end

  
  def currentServer
      if @type == "ec2"
          return @server['Public_DSN'].text
      elsif @type == "ops"
          return @ops_server['Addr'].text
      else
          return ""          
      end   
  end
  
  def securityGrps
       return @ec2_main.serverCache.securityGrps
  end 
  
  def instances
       return @ec2_main.serverCache.instances
  end 
  
  def instance_names
     return @ec2_main.serverCache.instance_names
  end
  
  def instance_running_names
     return @ec2_main.serverCache.running_names
  end 
  
  def instance_group(i)
      return @ec2_main.serverCache.instance_group(i)
  end    
  
  
  def securityGrps_Instances
       return @ec2_main.serverCache.sg_instances
  end 
  
  def running(group)
      return @ec2_main.serverCache.running(group)
  end
  
  def active(group)
        return @ec2_main.serverCache.active(group)
  end
  
  def load_server(server)
      sa = (server).split"/"
      if sa.size>1
         load(sa[sa.size-1])
      end        
  end
  
  def enable_if_env_set(sender)
        @env = @ec2_main.environment.env
       if @env != nil and @env.length>0
       	sender.enabled = true
       else
         sender.enabled = false
       end
       
 end 
   
 def enable_if_server_loaded(sender)
      if loaded and (@type == "ec2" or @type == "ops")
          sender.enabled = true
      else
          if rds_loaded and @type == "rds"
             sender.enabled = true
          else   
             sender.enabled = false
          end   
      end 
 end
 
 def enable_if_server_loaded_or_pending(sender)
       if loaded or  @server_status == "pending"
           sender.enabled = true
       else
           sender.enabled = false
       end 
 end
 
 def enable_if_ec2_server_loaded(sender)
        if loaded and (@type == "ec2" or @type == "ops")
            sender.enabled = true
        else
            sender.enabled = false
        end 
 end
  
  def enable_if_rds_server_loaded_or_pending(sender)
         if rds_loaded or  @server_status == "available" or @server_status == "failed"
             sender.enabled = true
         else
             sender.enabled = false
         end 
  end
  
  def enable_if_ec2_server_loaded_or_pending(sender)
        if loaded or  @server_status == "pending" 
            sender.enabled = true
        else
            sender.enabled = false
        end 
  end
 
  def enable_if_server_loaded_or_shuttingdown_or_terminated(sender)
        if loaded or  @server_status == "shutting-down" or @server_status == "terminated"
            sender.enabled = true
        else
            sender.enabled = false
        end 
  end
 
  def enable_if_ebs_ec2_server_loaded(sender)
         if  @type == "ec2" and @server['Root_Device_Type'].text == "ebs" and @server_status != "terminated"
             sender.enabled = true
         else
             sender.enabled = false
         end 
  end
 
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
    def run_chef
      	    private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')    
      	    chef_repository = @ec2_main.settings.get('CHEF_REPOSITORY')
            chef_node = @secgrp
            if @type == "ops"
               if @ops_server['Chef_Node'].text != nil and @ops_server['Chef_Node'].text != ""
                  chef_node = @ops_server['Chef_Node'].text
               end       	    
      	       node_name = "#{chef_repository}/nodes/#{chef_node}.json"
      	       ec2_server_name = @ops_server['Addr'].text
      	       ssh_user = @ops_server['SSH_User'].text            
            else
               if @server['Chef_Node'].text != nil and @server['Chef_Node'].text != ""
                  chef_node = @server['Chef_Node'].text
               end       	    
      	       node_name = "#{chef_repository}/nodes/#{chef_node}.json"
      	       ec2_server_name = @server['Public_DSN'].text
      	       ssh_user = @server['EC2_SSH_User'].text
      	    end   
      	    if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                if chef_repository != nil
                  chef_repository = chef_repository.gsub('/','\\') 
                end
                if private_key != nil
                   private_key = private_key.gsub('/','\\') 
                end
                node_name = node_name.gsub('/','\\') 
      	    end
      	    if chef_repository == nil or chef_repository == ""
               error_message("No Chef Repository","No CHEF_REPOSITORY specified in Settings")
               return
            end
            if private_key == nil or private_key == ""
               error_message("No ec2 ssh private key","No EC2_SSH_PRIVATE_KEY specified in Settings")
               return
            end
            if !File.exists?(node_name) 
               error_message("No Chef Node file","No Chef Node file #{node_name} for this server")
               return
            end
            if ec2_server_name == nil or ec2_server_name == ""
               error_message("No Public DSN","This Server does not have a Public DSN")
               return
            end
            short_name = ec2_server_name
            if ec2_server_name.size > 16
               sa = (ec2_server_name).split"."
               if sa.size>1
                  short_name = sa[0]
               end
            end
            answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Chef Solo","Confirm Running of Chef-Solo for Node #{chef_node} on server #{short_name}")
            if answer == MBOX_CLICKED_YES

               if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                  ENV["EC2_CHEF_REPOSITORY"] = chef_repository
                  ENV["EC2_SSH_PRIVATE_KEY"] = private_key
                  c = "cmd.exe /c \@start \"chef-solo #{chef_node} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push.bat\"  #{chef_node} #{ec2_server_name} #{ssh_user}"
    	          puts c
    	          system(c)
    	       else
    	          c = "#{ENV['EC2DREAM_HOME']}/chef/chef_push.sh #{chef_repository} #{chef_node} #{ec2_server_name} #{private_key} #{ssh_user}"
    	          puts c
    	          system(c)
    	       end   
    	    end
   end
end
