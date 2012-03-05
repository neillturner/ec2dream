require 'rubygems'
require 'fox16'
require 'fox16/colors'
require 'fox16/scintilla'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'tzinfo'
require 'dialog/EC2_CSVDialog'
require 'dialog/EC2_System_ConsoleDialog'
require 'dialog/EC2_MonitorDialog'
require 'cache/EC2_ServerCache'
require 'dialog/RDS_InstanceModifyDialog'
require 'dialog/RDS_InstanceDeleteDialog'
require 'dialog/EC2_ImageCreateDialog'
require 'dialog/EC2_ImageAttributeDialog'
require 'dialog/EC2_InstanceModifyDialog'
require 'dialog/EC2_SnapCreateDialog'
require 'common/EC2_ResourceTags'
require 'dialog/EC2_ImageRegisterDialog'

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
        @rds_server = {}
        @block_mapping = Array.new
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
	    if @type == "ec2" 
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
	   if @type == "ec2"
              run_scp
           else
              reboot_rds(@rds_server['DBInstanceId'].text)
           end
	end
	@winscp_button.connect(SEL_UPDATE) do |sender, sel, data|
           if loaded
	      sender.enabled = true
              @winscp_button.icon = @put
	      @winscp_button.tipText = "  SCP  "
	   else
	      if rds_loaded
	         sender.enabled = true
		 @winscp_button.icon = @reboot
	         @winscp_button.tipText = " Reboot  "
  	      else
	         sender.enabled = false
	      end   
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
	    else   
	       terminate
	    end  
	end
	@terminate_button.connect(SEL_UPDATE) do |sender, sel, data|
	    if @type == "ec2" and (@server_status == "running" or @server_status == "stopped"or @server_status == "pending") 
	       sender.enabled = true
	     else
	       sender.enabled = false
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
           else
              if rds_loaded
                 @log_button.icon = @modify
	         @log_button.tipText = " Modify DB Instance "
                 sender.enabled = true
              else
                 sender.enabled = false
              end   
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
                 n=g.gsub("_","-")+ "-" + today.strftime("%y%m%d")	      
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
		mondialog = EC2_MonitorDialog.new(@ec2_main,@server['Instance_ID'].text,@secgrp,data)
	       	mondialog.execute	 
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
 	   @server[''] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
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
	FXLabel.new(@frame1, "EC2 SSH User" )
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
  end 
  
  def loaded
     if @type == "ec2" and @server_status == "running" 
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
	      pk = get_pk
	      if pk != nil and pk != ""
	         pw = @server['Win_Admin_Password'].text
	         if pw != nil and pw != ""
	           c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" "+s+" 3389 Administrator "+s+" "+pw+" 0 1 0"
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
       return @server['Instance_ID'].text
  end

  
  def currentServer
     return @server['Public_DSN'].text
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
       @server_status = ""
       @secgrp = ""
       clear('Monitoring_State')
  end 
     
  def clear(key)
    @server[key].text = ""
  end 
 
  def load(instance_id)
         puts "load "+instance_id
         @type = "ec2"
         @frame1.show()
         @frame2.hide()
         @server['Instance_ID'].text = instance_id
         ENV['EC2_INSTANCE'] = instance_id
     	 r = @ec2_main.serverCache.instance(instance_id)
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
         #@server['Block_Devices'].text=""
         @server['Block_Devices'].clearItems
         load_block_mapping(r)
         @server['Instance_Life_Cycle'].text = r[:instance_life_cycle]
         @server['Spot_Instance_Request_Id'].text = r[:spot_instance_request_id]
     	 @ec2_main.app.forceRefresh
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
  if platform != "Eucalyptus"
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
   if platform != "Eucalyptus"
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

#
# rds methods
#

  def rds_loaded
         if @type == "rds" and @server_status == "available"
          return true
         else
          return false 
         end 
  end

  def run_mysql_admin
      addr = @rds_server['Address'].text
      port = @rds_server['Port'].text
      user = @rds_server['MasterUsername'].text
      pwd = ""
      if @rds_server['MasterUserPassword'].text != nil and @rds_server['MasterUserPassword'].text != ""
         pwd = @rds_server['MasterUserPassword'].text
      else   
         error_message("Error","No MySQL Master User Password specified")
         return
      end
      admin_cmd = "C:/Program Files/MySQL/MySQL Tools for 5.0/MySQLAdministrator.exe"
      if ENV['EC2DREAM_MYSQL_ADMIN'] != nil and ENV['EC2DREAM_MYSQL_ADMIN'] != ""
         admin_cmd = ENV['EC2DREAM_MYSQL_ADMIN']
      end
      if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
          c = "cmd.exe /c \@start \"\" /b \""+admin_cmd+"\" -h "+addr+" -P "+port+" -u "+user+" -p "+pwd
  	  puts c
  	  system(c)
      end
  end

  def load_rds_server(server)
        sa = (server).split"/"
        if sa.size>1
          load_rds(sa[sa.size-1])
        end        
  end

 def clear_rds_panel
     @type = ""
     ENV['EC2_INSTANCE'] = ""
     rds_clear('DBSecurity_Groups')
     rds_clear('DBInstanceId')
     rds_clear('DBName')
     rds_clear('DBInstanceClass')
     rds_clear('AllocatedStorage')
     rds_clear('AvailabilityZone')
     rds_clear('MultiAZ')
     rds_clear('Engine')
     rds_clear('EngineVersion')
     rds_clear('MasterUsername')
     rds_clear('MasterUserPassword')
     rds_clear('DBInstance_Status')
     rds_clear('Instance_Create_Time')
     rds_clear('Latest_Restorable_Time')
     rds_clear('PreferredMaintenanceWindow')
     rds_clear('DBParameterGroupName')
     rds_clear('BackupRetentionPeriod')
     rds_clear('PreferredBackupWindow')
     rds_clear('Port')
     rds_clear('Address')
     rds_clear('AutoMinorVersionUpgrade')
     rds_clear('ReadReplicaSourceDBInstanceId')
     rds_clear('ReadReplicaDBInstanceIds') 
     @frame1.hide()
     @page1.width=300
     @frame2.show()
     @server_status = ""
     @secgrp = ""
     @ec2_main.app.forceRefresh()
  end

  def rds_clear(key)
    @rds_server[key].text = ""
  end    

def load_rds(instance_id)
      puts "load_rds #{instance_id}"
      @type = "rds"
      @frame1.hide()
      @frame2.show()
      #clear_rds_panel
      @rds_server['DBInstanceId'].text=instance_id
      r = @ec2_main.serverCache.DBInstance(instance_id)
      if r == nil
         @server_status = "Deleted"
	 @rds_server['DBInstance_Status'].text="Deleted"
	 @rds_server['Port'].text=""
	 @rds_server['Address'].text=""
      else
         @rds_server['DBSecurity_Groups'].text=""
         @rds_server['DBName'].text=""
         @rds_server['DBInstanceClass'].text=""
         @rds_server['AllocatedStorage'].text=""
         @rds_server['AvailabilityZone'].text=""
         @rds_server['MultiAZ'].text=""
         @rds_server['Engine'].text=""
         @rds_server['EngineVersion'].text=""
         @rds_server['MasterUsername'].text=""
         @rds_server['MasterUserPassword'].text=""
         @rds_server['DBInstance_Status'].text=""  
         @rds_server['Instance_Create_Time'].text=""	   
         @rds_server['Latest_Restorable_Time'].text=""    
         @rds_server['PreferredMaintenanceWindow'].text=""
         @rds_server['DBParameterGroupName'].text = ""
         @rds_server['BackupRetentionPeriod'].text=""
         @rds_server['PreferredBackupWindow'].text=""
         @rds_server['Port'].text=""	
         @rds_server['Address'].text=""
         @rds_server['AutoMinorVersionUpgrade'].text="" 
         @rds_server['ReadReplicaSourceDBInstanceId'].text="" 
         @rds_server['ReadReplicaDBInstanceIds'].text="" 
         @server_status = ""
         
         if r[:db_security_groups] != nil
	    if r[:db_security_groups].class == Array
      	       gp = r[:db_security_groups]
      	       gp_list = ""
      	       if gp != nil
      	          gp.each do |g|
      	             if gp_list.length>0
      	                gp_list = "#{gp_list},#{g[:name]} (#{g[:status]})"
      	             else
 			gp_list = "#{g[:name]} (#{g[:status]})"
      	                @secgrp = g[:name]
      	             end   
      	          end 
      	       end
      	       @rds_server['DBSecurity_Groups'].text=gp_list
      	    end     	       
      	 end   
	 if r[:name] != nil
	    @rds_server['DBName'].text=r[:name]
	 end   
	 if r[:instance_class] != nil   
	    @rds_server['DBInstanceClass'].text=r[:instance_class]
 	 end 
	 if r[:allocated_storage] != nil
	    @rds_server['AllocatedStorage'].text=r[:allocated_storage].to_s
	 end   
	 if r[:availability_zone] != nil
	    @rds_server['AvailabilityZone'].text=r[:availability_zone]
	 end 
	 if r[:multi_az] != nil
	    @rds_server['MultiAZ'].text=r[:multi_az].to_s
	 end     
	 if r[:engine] != nil
	    @rds_server['Engine'].text=r[:engine]
	 end 
	 if r[:engine_version] != nil
	    @rds_server['EngineVersion'].text=r[:engine_version]
	 end     
	 if r[:master_username] != nil
	    @rds_server['MasterUsername'].text=r[:master_username]
	 end
	 if @mysql_admin_pw[instance_id] != nil 
	    @rds_server['MasterUserPassword'].text=@mysql_admin_pw[instance_id]
	 end
	 if r[:status] != nil
	    puts "Status #{r[:status]}"
	    @server_status = r[:status]
	    @rds_server['DBInstance_Status'].text=r[:status]
	 end 
     	 t = r[:create_time]
     	 if t != nil
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
	    @rds_server['Instance_Create_Time'].text=t
	 end
         @rds_server['Latest_Restorable_Time'].text = ""
	 t = r[:latest_restorable_time]
     	 if t != nil
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
	    @rds_server['Latest_Restorable_Time'].text=t
	 end	 
         @rds_server['PreferredMaintenanceWindow'].text = ""
	 if r[:preferred_maintenance_window] != nil
	    @rds_server['PreferredMaintenanceWindow'].text=r[:preferred_maintenance_window]
	 end
	 if r[:db_parameter_group] != nil
	    gp = r[:db_parameter_group]
	    @rds_server['DBParameterGroupName'].text = gp[:name]+" ("+gp[:status]+")"
     	 end	 
	 if r[:backup_retention_period] != nil
	    @rds_server['BackupRetentionPeriod'].text=r[:backup_retention_period].to_s
	 end   
	 if r[:preferred_backup_window] != nil
	    @rds_server['PreferredBackupWindow'].text=r[:preferred_backup_window]
	 end   
	 if r[:endpoint_port] != nil
	    @rds_server['Port'].text=r[:endpoint_port].to_s
	 end   
	 if r[:endpoint_address] != nil
	    @rds_server['Address'].text=r[:endpoint_address]
	 end 
	 if r[:auto_minor_version_upgrade] != nil
	    @rds_server['AutoMinorVersionUpgrade'].text=r[:auto_minor_version_upgrade].to_s
	 end 
	 if r[:read_replica_source_db_instance_id] != nil
	    @rds_server['ReadReplicaSourceDBInstanceId'].text=r[:read_replica_source_db_instance_id]
	 end 
	 if r[:read_replica_db_instance_ids] != nil
	    if r[:read_replica_db_instance_ids].class == Array
     	       rr_list = ""
     	       r[:read_replica_db_instance_ids].each do |rr|
     	          if rr_list.length>0
                     rr_list = "#{rr_list},#{rr}"
     	          else
     	             rr_list = "#{rr}"
     	          end 
     	       end
	       @rds_server['ReadReplicaDBInstanceIds'].text=rr_list
	    end
	 end   
      end
      @page1.width=300
      @ec2_main.app.forceRefresh
 end

 def reboot_rds(instance)
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Reboot","Confirm Reboot of DB Instance "+instance)
      if answer == MBOX_CLICKED_YES
         rds = @ec2_main.environment.rds_connection
         if rds != nil
            begin
               r = rds.reboot_db_instance(instance)
               @rebooted = true
            rescue
               error_message("Reboot DB Instance Failed",$!.to_s)
            end      
         end
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
      if loaded and @type == "ec2"
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
        if loaded and @type == "ec2"
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
        if loaded or  @server_status == "pending" and @type == "ec2"
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
            if @server['Chef_Node'].text != nil and @server['Chef_Node'].text != ""
               chef_node = @server['Chef_Node'].text
            end       	    
      	    node_name = "#{chef_repository}/nodes/#{chef_node}.json"
      	    ec2_server_name = @server['Public_DSN'].text
      	    ssh_user = @server['EC2_SSH_User'].text
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
            sa = (ec2_server_name).split"."
            if sa.size>1
               short_name = sa[0]
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
