class EC2_Server

  def initialize(owner)
    @ec2_main = owner
    @securityGrps = Array.new
    @secgrp =""
    @type = ""
    @appname = ""
    @windows_admin_pw = {}
    @command_stack = {}
    @ec2_ssh_user = {}
    @ec2_ssh_private_key = {}
    @ec2_chef_node = {}
    @ec2_puppet_manifest = {}
    @putty_private_key = {}
    @mysql_admin_pw = {}
    @bastion = {}
    @local_port = {}
    @server_status = ""
    @server = {}
    @resource_tags = nil
    @ops_server = {}
    @ops_public_addr = {}
    @ops_admin_pw = {}
    @google_server = {}
    @google_public_addr = {}
    @google_admin_pw = {}
    @azure_server = {}
    #@cfy_env = []
    #@cfy_env_curr_row = nil
    @loc_server = {}
    @saved = false
    @block_mapping = []
    @flavor = {}
    @image = {}
    @softlayer_server = {}
    @softlayer_public_addr = {}
    @softlayer_admin_pw = {}
    @curr_row = nil
    @arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
    @arrow_refresh.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @monitor = @ec2_main.makeIcon("monitor.png")
    @monitor.create
    @upload = @ec2_main.makeIcon("arrow_up.png")
    @upload.create
    @put = @ec2_main.makeIcon("application_put.png")
    @put.create
    @reboot = @ec2_main.makeIcon("arrow_red_redo.png")
    @reboot.create
    @desktop = @ec2_main.makeIcon("windows.png")
    @desktop.create
    @disconnect = @ec2_main.makeIcon("disconnect.png")
    @disconnect.create
    @mon = @ec2_main.makeIcon("dashboard.png")
    @mon.create
    @unmon = @ec2_main.makeIcon("dashboard_stop.png")
    @unmon.create
    @start_icon = @ec2_main.makeIcon("arrow_right.png")
    @start_icon.create
    @log = @ec2_main.makeIcon("script.png")
    @log.create
    @modify = @ec2_main.makeIcon("application_edit.png")
    @modify.create
    @edit = @ec2_main.makeIcon("accept.png")
    @edit.create
    @stop_icon = @ec2_main.makeIcon("cancel.png")
    @stop_icon.create
    @create_image_icon = @ec2_main.makeIcon("package.png")
    @create_image_icon.create
    @view = @ec2_main.makeIcon("application_view_icons.png")
    @view.create
    @tag_red = @ec2_main.makeIcon("tag_red.png")
    @tag_red.create
    @market_icon = @ec2_main.makeIcon("cloudmarket.png")
    @market_icon.create
    @key = @ec2_main.makeIcon("key.png")
    @key.create
    @camera = @ec2_main.makeIcon("camera.png")
    @camera.create
    @create = @ec2_main.makeIcon("new.png")
    @create.create
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create
    @chart = @ec2_main.makeIcon("chart_stock.png")
    @chart.create
    @tunnel = @ec2_main.makeIcon("tunnel.png")
    @tunnel.create
    @save = @ec2_main.makeIcon("disk.png")
    @save.create
    @rocket = @ec2_main.makeIcon("rocket.png")
    @rocket.create
    @arrow_in = @ec2_main.makeIcon("arrow_in.png")
    @arrow_in.create
    @bug = @ec2_main.makeIcon("bug.png")
    @bug.create
    @style = @ec2_main.makeIcon("style.png")
    @style.create
    @lightbulb = @ec2_main.makeIcon("lightbulb.png")
    @lightbulb.create
    @link = @ec2_main.makeIcon("link_break.png")
    @link.create

    tab2 = FXTabItem.new(@ec2_main.tabBook, " Server ")
    @page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
    page1a = FXHorizontalFrame.new(@page1,LAYOUT_FILL_X, :padding => 0)
    @server_label = FXLabel.new(page1a, "" )
    @refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @refresh_button.icon = @arrow_refresh
    @refresh_button.tipText = "Server Status Refresh"
    @refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2"  or @type == "ops" or @type == "google" or @type == "softlayer" or @type == "azure"
        begin
          s = currentInstance
          if s != nil and s != ""
            @ec2_main.serverCache.refresh(s) if @type == "ec2"  or @type == "ops" or @type == "google"
            load(s)
          end
        rescue
        end
      end
    end
    @refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
      enable_if_env_set(sender)
    end
    @putty_button = FXButton.new(page1a," ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @putty_button.icon = @monitor
    @putty_button.tipText = " SSH "
    @putty_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2" or @type == "ops" or @type == "google" or @type == "softlayer" or @type == "azure"
        run_ssh
      elsif @type == "loc"
        loc_ssh
      end
    end
    @putty_button.connect(SEL_UPDATE) do |sender, sel, data|
      enable_if_server_loaded(sender)
      if loaded
        @putty_button.icon = @monitor
        @putty_button.tipText = " SSH "
      end
    end
    @winscp_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @winscp_button.icon = @put
    @winscp_button.tipText = "  SCP  "
    @winscp_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2" or @type == "ops"  or @type == "google" or @type == "softlayer" or @type == "azure"
        run_scp
      elsif @type == "loc"
        loc_winscp
      end
    end
    @winscp_button.connect(SEL_UPDATE) do |sender, sel, data|
      if loaded
        sender.enabled = true
        @winscp_button.icon = @put
        @winscp_button.tipText = "  SCP  "
      else
        sender.enabled = false
      end
    end
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("mingw") != nil
      @remote_desktop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
      @remote_desktop_button.icon = @desktop
      @remote_desktop_button.tipText = " Windows Remote Desktop "
      @remote_desktop_button.connect(SEL_COMMAND) do |sender, sel, data|
        puts "server.serverRemote_Desktop.connect"
        if @type == "loc"
          loc_rdp
        else
          run_remote_desktop
        end
      end
      @remote_desktop_button.connect(SEL_UPDATE) do |sender, sel, data|
        enable_if_ec2_server_loaded(sender)
      end
    end
    @terminate_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @terminate_button.icon = @disconnect
    @terminate_button.tipText = " Terminate Instance "
    @terminate_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2"
        terminate
      elsif @type == "ops"
        ops_terminate
      elsif @type == "google"
        google_terminate
      elsif @type == "softlayer"
        softlayer_terminate
      elsif @type == "azure"
        azure_terminate
      elsif @type == "loc"
        loc_save
      end
    end
    @terminate_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = false
      @terminate_button.icon = @disconnect
      @terminate_button.tipText = " Terminate Instance "
      if @type == "ec2" and (@server_status == "running" or @server_status == "stopped"or @server_status == "pending")
        sender.enabled = true
      elsif @type == "ops" and (@server_status == "ACTIVE"  or @server_status == "BUILD")
        sender.enabled = true
      elsif @type == "google" and (@server_status == "RUNNING")
        sender.enabled = true
      elsif @type == "softlayer"  and @softlayer_server['Created_At'].text!=nil and @softlayer_server['Created_At'].text!=""
        sender.enabled = true
      elsif @type == "loc"
        @terminate_button.icon = @save
        sender.enabled = true
        @terminate_button.tipText = " Save Configuration "
      end
    end
    @log_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @log_button.icon = @log
    @log_button.tipText = " Console Output "
    @log_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2" or  @type == "ops"
        s = currentInstance()
        g =instance_group(s)
        dialog = EC2_System_ConsoleDialog.new(@ec2_main,g,s)
        dialog.execute
      end
    end
    @log_button.connect(SEL_UPDATE) do |sender, sel, data|
      if loaded or  @server_status == "pending" and @type == "ec2"
        @log_button.icon = @log
        @log_button.tipText = " Console Output "
        sender.enabled = true
      elsif loaded and @type == "ops"
        @log_button.icon = @log
        @log_button.tipText = " Console Output "
        sender.enabled = true
      else
        sender.enabled = false
      end
    end
    @mon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @mon_button.icon = @mon
    @mon_button.tipText = " Monitor Instance "
    @mon_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "loc"
        loc_delete
      else
        monitor
      end
    end
    @mon_button.connect(SEL_UPDATE) do |sender, sel, data|
      enable_if_ec2_server_loaded_or_pending(sender) unless (@type == "cfy" or @type == "loc")
      if @type == "loc"
        @mon_button.icon = @delete
        sender.enabled = true
        @terminate_button.tipText = " Delete Configuration "
      else
        @mon_button.icon = @mon
        @mon_button.tipText = " Monitor Instance "
      end
    end
    @unmon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @unmon_button.icon = @unmon
    @unmon_button.tipText = " Stop Monitoring Instance "
    @unmon_button.connect(SEL_COMMAND) do |sender, sel, data|
      unMonitor
    end
    @unmon_button.connect(SEL_UPDATE) do |sender, sel, data|
      enable_if_ec2_server_loaded_or_pending(sender) unless (@type == "cfy" or @type == "loc")
    end
    @start_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @start_button.icon = @start_icon
    @start_button.tipText = " Start Instance "
    @start_button.connect(SEL_COMMAND) do |sender, sel, data|
      start_instance
    end
    @start_button.connect(SEL_UPDATE) do |sender, sel, data|
      enable_if_ebs_ec2_server_loaded(sender)
    end
    @stop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @stop_button.icon = @stop_icon
    @stop_button.tipText = " Stop Instance "
    @stop_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2"
        stop_instance
      elsif @type == "ops"
        instance = @ops_server['Instance_ID'].text
        dialog = EC2_InstanceRebootDialog.new(@ec2_main,instance)
        dialog.execute
        if dialog.rebooted
          FXMessageBox.information(@ec2_main,MBOX_OK,"Instance Rebooted","Server Instance #{instance} Rebooted")
        end
      end
    end
    @stop_button.connect(SEL_UPDATE) do |sender, sel, data|
      if loaded and @type == "ec2"
        sender.enabled = true
        @stop_button.icon = @stop_icon
        @stop_button.tipText = " Stop Instance "
      elsif loaded and @type == "ops"
        sender.enabled = true
        @stop_button.icon = @reboot
        @stop_button.tipText = " Reboot  "
      else
        sender.enabled = false
      end
    end
    @create_image_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @create_image_button.icon = @create_image_icon
    @create_image_button.tipText = " Create Image "
    @create_image_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2" or @type == "ops"
        if @server['Root_Device_Type'].text == "ebs"  or @type == "ops"
          s = currentInstance()
          today = DateTime.now
          g =instance_group(s)
          n=g.gsub("_","-")+ "-" + today.strftime("%Y%m%d")
          dialog = EC2_ImageCreateDialog.new(@ec2_main,s,n)
          dialog.execute
          if dialog.created
            image_id = dialog.image_id
            FXMessageBox.information(@ec2_main,MBOX_OK,"EBS Image","EBS Image #{image_id} created")
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
      elsif @type == "ops" and @server_status == "ACTIVE"
        sender.enabled = true
      else
        sender.enabled = false
      end
    end
    @graph_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @graph_button.icon = @chart
    @graph_button.tipText = " Monitoring Graphs "
    @graph_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2"
        dialog = EC2_MonitorSelectDialog.new(@ec2_main,@server['Instance_ID'].text,"InstanceId",@secgrp,@server['Platform'].text)
        dialog.execute
      end
    end
    @graph_button.connect(SEL_UPDATE) do |sender, sel, data|
      if @type == "ec2"
        @graph_button.icon = @chart
        @graph_button.tipText = " Monitoring Graphs "
        sender.enabled = true
      else
        sender.enabled = false
      end
    end
    @tunnel_button = FXButton.new(page1a," ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @tunnel_button.icon = @tunnel
    @tunnel_button.tipText = " Setup SSH Tunnel"
    @tunnel_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @type == "ec2" or @type == "ops"  or @type == "google"
        run_ssh_tunnel
      elsif @type == "loc"
        loc_ssh_tunnel
      end
    end
    @tunnel_button.connect(SEL_UPDATE) do |sender, sel, data|
      if loaded
        sender.enabled = true
      else
        sender.enabled = false
      end
    end
    #
    # aws
    #
    @frame1 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "Security Groups" )
    @frame1s = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Security_Groups'] = FXTextField.new(@frame1s, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Security_Groups_Button'] = FXButton.new(@frame1s, " ",:opts => BUTTON_TOOLBAR)
    @server['Security_Groups_Button'].icon = @view
    @server['Security_Groups_Button'].tipText = "  Modify Instance Attributes  "
    @server['Security_Groups_Button'].connect(SEL_COMMAND) do |sender, sel, data|
      @curr_item = @server['Instance_ID'].text
      if @curr_item == nil or @curr_item == ""
        error_message("No Instance Id","No Instance Id to modify attributes")
      else
        dialog = EC2_InstanceModifyDialog.new(@ec2_main,@server['Instance_ID'].text)
        dialog.execute
      end
    end
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Instance Id" )
    @frame1t = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Instance_ID'] = FXTextField.new(@frame1t, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Instance_ID_Button'] = FXButton.new(@frame1t, " ",:opts => BUTTON_TOOLBAR)
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
    FXLabel.new(@frame1t, "IAM Role" )
    @server['test_kitchen_path'] = FXTextField.new(@frame1t, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Tags" )
    @server['Tags'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Tags_button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
    @server['Tags_button'].icon = @tag_red
    @server['Tags_button'].tipText = "  Edit Tags  "
    @server['Tags_button'].connect(SEL_COMMAND) do |sender, sel, data|
      @curr_item = @server['Instance_ID'].text
      if @curr_item == nil or @curr_item == ""
        error_message("No Instance Id","No Instance Id to modify attributes")
      else
        dialog = EC2_TagsAssignDialog.new(@ec2_main,@curr_item)
        dialog.execute
        if dialog.saved
          s = currentInstance
          if s != nil and s != ""
            @ec2_main.serverCache.refresh(s)
            load(s)
          end
        end
      end
    end
    FXLabel.new(@frame1, "Image Id" )
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
        dialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
        dialog.execute
      end
    end
    @server['market_button'] = FXButton.new(@frame1a, " ",:opts => BUTTON_TOOLBAR)

    @server['market_button'].icon = @market_icon
    @server['market_button'].tipText = "  CloudMarket Info  "
    @server['market_button'].connect(SEL_COMMAND) do |sender, sel, data|
      browser("http://thecloudmarket.com/image/#{@server['Image_ID'].text}")
    end
    FXLabel.new(@frame1, "State" )
    @frame1j = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['State'] = FXTextField.new(@frame1j, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['State'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
    FXLabel.new(@frame1j, "       Launch Time" )
    @server['Launch_Time'] = FXTextField.new(@frame1j, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Public DSN" )
    @server['Public_DSN'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Private DSN" )
    @server['Private_DSN'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    @server['Public_IP_label'] = FXLabel.new(@frame1, "Public IP" )
    @server['Public_IP_label'].tipText = "Public IP is used before private IP as address for ssh.\nClear the Public IP to ssh to server via Private IP."
    @frame1ip = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Public_IP'] = FXTextField.new(@frame1ip, 25, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(@frame1ip, "Private IP" )
    @server['Private_IP'] = FXTextField.new(@frame1ip, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Subnet Id" )
    @frame1e = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Subnet_Id'] = FXTextField.new(@frame1e, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1e, "    VPC Id" )
    @server['Vpc_Id'] = FXTextField.new(@frame1e, 25, nil, 0, :opts => TEXTFIELD_READONLY)
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
    #FXLabel.new(@frame1, "Launch Time" )
    #@server['Launch_Time'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame1, "" )
    #if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
      @server['EC2_SSH_Private_Key_label'] = FXLabel.new(@frame1, "EC2 SSH Private Key" )
      @server['EC2_SSH_Private_Key_label'].tipText = "OPTIONAL: SSH Key for SSH access to the server.\nDEFAULT: defaults to value specified in Environment tab."
      @server['EC2_SSH_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @server['EC2_SSH_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @server['Instance_ID'].text
        @ec2_ssh_private_key[instance_id] = @server['EC2_SSH_Private_Key'].text
        if @ec2_main.launch.loaded == true
          @ec2_main.launch.put('EC2_SSH_Private_Key',@server['EC2_SSH_Private_Key'].text)
          @ec2_main.launch.save
        end
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
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.put('EC2_SSH_Private_Key',@server['EC2_SSH_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("mingw") != nil
      @server['Putty_Private_Key_label'] = FXLabel.new(@frame1, "Putty Private Key" )
      @server['Putty_Private_Key_label'].tipText = "OPTIONAL: Putty Key for Putty access to the server.\nDEFAULT: defaults to value specified in Environment tab."
      @server['Putty_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @server['Putty_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @server['Instance_ID'].text
        @putty_private_key[instance_id] = @server['Putty_Private_Key'].text
        if @ec2_main.launch.loaded == true
          @ec2_main.launch.put('Putty_Private_Key',@server['Putty_Private_Key'].text)
          @ec2_main.launch.save
        end
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
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.put('Putty_Private_Key',@server['Putty_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    end
    @server['EC2_SSH_User_label'] = FXLabel.new(@frame1, "EC2 SSH/Windows User" )
    @server['EC2_SSH_User_label'].tipText = "OPTIONAL: SSH User for SSH access to the server.\nFor Windows Server Remote Desktop user.\nDEFAULT: defaults to value specified in Environment tab."
    @frame1su = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['EC2_SSH_User'] = FXTextField.new(@frame1su, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @server['EC2_SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
      instance_id = @server['Instance_ID'].text
      @ec2_ssh_user[instance_id] = data
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.put('EC2_SSH_User',data)
        @ec2_main.launch.save
      end
    end
    @server['Win_Admin_Password_label'] = FXLabel.new(@frame1su, "Win Admin Pswd" )
    @server['Win_Admin_Password_label'].tipText = "OPTIONAL: Windows Administrator user password for use with Remote Desktop.\nCan be populated by pressing 'Decrypt Windows Admin Password' button\n.It my take several minutes after the Windows Server is started before a decrypted is returned."
    @server['Win_Admin_Password'] = FXTextField.new(@frame1su, 20, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_PASSWD)
    @server['Win_Admin_Password'].connect(SEL_COMMAND) do |sender, sel, data|
      instance_id = @server['Instance_ID'].text
      @windows_admin_pw[instance_id] = data
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.put('Win_Admin_Password',data)
        @ec2_main.launch.save
      end
    end
    @frame1g = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Win_Admin_Password_Button'] = FXButton.new(@frame1g, "", :opts => BUTTON_TOOLBAR)
    @server['Win_Admin_Password_Button'].icon = @key
    @server['Win_Admin_Password_Button'].tipText = "Decrypt Windows Admin Password"
    @server['Win_Admin_Password_Button'].connect(SEL_COMMAND) do
      if loaded
        pk = get_pk
        if pk != nil and pk != ""
          if File.exists?(pk)
            puts "loading "+pk
            f = File.open(pk, "r")
            pk_text = f.read
            f.close
            begin
              pw = @ec2_main.environment.servers.get_initial_password(@server['Instance_ID'], pk_text)
              if pw != nil and pw != ""
                @server['Win_Admin_Password'].text = pw
                instance_id = @server['Instance_ID'].text
                @windows_admin_pw[instance_id] = pw
                if @ec2_main.launch.loaded == true
                  @ec2_main.launch.put('Win_Admin_Password',pw)
                  @ec2_main.launch.save
                end
                FXMessageBox.information(@ec2_main,MBOX_OK,"Win Admin Password","Windows Admin password #{pw} saved")
              else
                FXMessageBox.information(@ec2_main,MBOX_OK,"Win Admin Password"," Unable to get Windows password")
              end
            rescue
              error_message("Error - Unable to get Windows password", $!)
            end
          else
            error_message("Error","EC2 SSH Private Key Specified in server profile does not exist")
          end
        else
          error_message("Error","No EC2 SSH Private Key Specified in server profile")
        end
      else
        error_message("Error","Server not running. Press refresh")
      end
    end
    @server['Win_Admin_Password_Button2'] = FXButton.new(@frame1g, "", :opts => BUTTON_TOOLBAR)
    @server['Win_Admin_Password_Button2'].icon = @magnifier
    @server['Win_Admin_Password_Button2'].tipText = "Show Windows Admin Password"
    @server['Win_Admin_Password_Button2'].connect(SEL_COMMAND) do
      dialog = EC2_ShowPasswordDialog.new(@ec2_main,"Win Admin Password",@server['Win_Admin_Password'].text)
      dialog.execute
    end
    @server['Local_Port_label'] = FXLabel.new(@frame1, "Local Port (SSH Tunneling)" )
    @server['Local_Port_label'].tipText = "OPTIONAL: SSH port to use if different from default 22.\nTypically used when doing SSH Tunneling."
    @frame1su = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Local_Port'] = FXTextField.new(@frame1su, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @server['Local_Port'].connect(SEL_COMMAND) do  |sender, sel, data|
      instance_id = @server['Instance_ID'].text
      @local_port[instance_id] = data
      @ec2_main.launch.put('Local_Port',data)
      @ec2_main.launch.save
    end
    @server['Local_Port_Button'] = FXButton.new(@frame1su, "", :opts => BUTTON_TOOLBAR)
    @server['Local_Port_Button'].icon = @tunnel
    @server['Local_Port_Button'].tipText = "  Configure Bastion Host  "
    @server['Local_Port_Button'].connect(SEL_COMMAND) do
      r = {}
      instance_id = @server['Instance_ID'].text
      r = @bastion[instance_id] if @bastion[instance_id] != nil
      dialog = EC2_BastionEditDialog.new(@ec2_main,r)
      dialog.execute
      if dialog.saved
        r = dialog.selected
        if r != nil and r != ""
          @bastion[instance_id] = r
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.save_bastion(r)
            @ec2_main.launch.save
          end
        end
      end
    end
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "AMI Launch Index" )
    @server['Ami_Launch_Index'] = FXTextField.new(@frame1, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Kernel Id" )
    @frame1f = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Kernel_Id'] = FXTextField.new(@frame1f, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1f, "                 Ramdisk Id" )
    @server['Ramdisk_Id'] = FXTextField.new(@frame1f, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Platform" )
    @frame1h = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Platform'] = FXTextField.new(@frame1h, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1h, "  Ebs Optimized" )
    @server['Ebs_Optimized'] =  FXTextField.new(@frame1h, 15, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Root Device Type" )
    @frame1d = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Root_Device_Type'] = FXTextField.new(@frame1d, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1d, "     Root Device Name" )
    @server['Root_Device_Name'] = FXTextField.new(@frame1d, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    @server['Block_Devices_label'] = FXLabel.new(@frame1, "Block Devices (EBS)")
    @server['Block_Devices_label'].tipText = "Elastic Block Devices attached to the server"
    @server['Block_Devices'] = FXTable.new(@frame1,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    @server['Block_Devices'].connect(SEL_COMMAND) do |sender, sel, which|
      @curr_row = which.row
      @server['Block_Devices'].selectRow(@curr_row)
    end
    @server['Block_Devices_Button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
    @server['Block_Devices_Button'].icon = @camera
    @server['Block_Devices_Button'].tipText = "  Snapshot Block Device  "
    @server['Block_Devices_Button'].connect(SEL_COMMAND) do |sender, sel, data|
      if @curr_row == nil or  @server['Block_Devices'].anythingSelected? == false
        error_message("No Block Device","No Block Device selected to snapshot")
      else
        row = @server['Block_Devices'].getItemText(@curr_row,0)
        sa = (row).split";"
        if sa.size>1
          dialog = EC2_SnapVolumeDialog.new(@ec2_main,sa[1])
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
    # ops frame
    #
    @frame3 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame3.hide()
    FXLabel.new(@frame3, "Name" )
    @frame3s = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
    @ops_server['Name'] = FXTextField.new(@frame3s, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame3, "" )
    FXLabel.new(@frame3, "Security Groups" )
    @frame3t = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
    @ops_server['Security_Groups'] = FXTextField.new(@frame3t, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame3, "" )
    FXLabel.new(@frame3, "Instance ID" )
    @ops_server['Instance_ID'] = FXTextField.new(@frame3, 50, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame3, "" )
    FXLabel.new(@frame3, "Image ID" )
    @ops_server['Image_ID'] = FXTextField.new(@frame3, 50, nil, 0, :opts => TEXTFIELD_READONLY)
    @ops_server['attributes_button'] = FXButton.new(@frame3, " ",:opts => BUTTON_TOOLBAR)
    @ops_server['attributes_button'].icon = @view
    @ops_server['attributes_button'].tipText = "  Image Attributes  "
    @ops_server['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
      @curr_item = @ops_server['Image_ID'].text
      if @curr_item == nil or @curr_item == ""
        error_message("No Image Id","No Image Id specified to display attributes")
      else
        dialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
        dialog.execute
      end
    end
    FXLabel.new(@frame3, "State" )
    @frame3j = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
    @ops_server['State'] = FXTextField.new(@frame3j, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    @ops_server['State'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
    FXLabel.new(@frame3j, "       Launch Time" )
    @ops_server['Launch_Time'] = FXTextField.new(@frame3j, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame3, "" )
    FXLabel.new(@frame3, "Addresses" )
    @ops_server['Addresses'] = FXTextField.new(@frame3, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame3, "" )
    @ops_server['Public_Addr_label'] = FXLabel.new(@frame3, "Public IP Addr" )
    @ops_server['Public_Addr_label'].tipText = "Public IP Address used by SSH to access the server.\nOverride the address if you need to access it via a different IP Address"
    @ops_server['Public_Addr'] = FXTextField.new(@frame3, 40, nil, 0, :opts => FRAME_SUNKEN)
    @ops_server['Public_Addr'].connect(SEL_COMMAND) do  |sender, sel, data|
      instance_id = @ops_server['Instance_ID'].text
      @ops_public_addr[instance_id] = data
      #@ec2_main.launch.ops_put('Public_Addr',data)
      #@ec2_main.launch.ops_save
    end
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
    if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
      @ops_server['SSH_Private_Key_label'] = FXLabel.new(@frame3,"SSH Private Key" )
      @ops_server['SSH_Private_Key_label'].tipText = "OPTIONAL: SSH Key for SSH access to the server.\nDEFAULT: defaults to value specified in Environment tab."
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
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('SSH_Private_Key',@ops_server['SSH_Private_Key'].text)
            @ec2_main.launch.ops_save
          end
        end
      end
    else
      @ops_server['Putty_Private_Key_label'] = FXLabel.new(@frame3, "Putty Private Key" )
      @ops_server['Putty_Private_Key_label'].tipText = "OPTIONAL: Putty Key for Putty access to the server.\nDEFAULT: defaults to value specified in Environment tab."
      @ops_server['Putty_Private_Key'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @ops_server['Putty_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @ops_server['Instance_ID'].text
        @putty_private_key[instance_id] = @ops_server['Putty_Private_Key'].text
        if @ec2_main.launch.loaded == true
          @ec2_main.launch.ops_put('Putty_Private_Key',@ops_server['Putty_Private_Key'].text)
          @ec2_main.launch.ops_save
        end
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
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('Putty_Private_Key',@ops_server['Putty_Private_Key'].text)
            @ec2_main.launch.ops_save
          end
        end
      end
    end
    @ops_server['EC2_SSH_User_label'] = FXLabel.new(@frame3, "SSH/Win Admin User" )
    @ops_server['EC2_SSH_User_label'].tipText = "OPTIONAL: SSH User for SSH access to the server.\nFor Windows Server Remote Desktop user.\nDEFAULT: defaults to value specified in Environment tab."
    @ops_server['EC2_SSH_User'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @ops_server['EC2_SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.ops_put('EC2_SSH_User',data)
        @ec2_main.launch.ops_save
      end
    end
    FXLabel.new(@frame3, "" )
    @ops_server['Admin_Password_label'] = FXLabel.new(@frame3, "SSH/Win Admin Password" )
    @ops_server['Admin_Password_label'].tipText = "OPTIONAL: SSH user or Windows Administrator user password for use with Remote Desktop."
    @ops_server['Admin_Password'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_PASSWD)
    @ops_server['Admin_Password'].connect(SEL_COMMAND) do |sender, sel, data|
      instance_id = @ops_server['Instance_ID'].text
      @ops_admin_pw[instance_id] = data
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.ops_put('Admin_Password',data)
        @ec2_main.launch.ops_save
      end
    end
    @frame3g = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
    @ops_server['Admin_Password_Button'] = FXButton.new(@frame3g, "", :opts => BUTTON_TOOLBAR)
    @ops_server['Admin_Password_Button'].icon = @key
    @ops_server['Admin_Password_Button'].tipText = "Change Admin Password"
    @ops_server['Admin_Password_Button'].connect(SEL_COMMAND) do
      if loaded
        begin
          instance_id = @ops_server['Instance_ID'].text
          dialog = EC2_InstanceAdminPasswordDialog.new(@ec2_main,instance_id)
          dialog.execute
          if dialog.updated
            pw = dialog.selected
            @ops_server['Admin_Password'].text = pw
            instance_id = @ops_server['Instance_ID'].text
            @ops_admin_pw[instance_id] = pw
            if @ec2_main.launch.loaded == true
              @ec2_main.launch.ops_put('Admin_Password',pw)
              @ec2_main.launch.ops_save
            end
            FXMessageBox.information(@ec2_main,MBOX_OK,"Admin Password","Admin password #{pw} saved")
          end
        rescue
          error_message("Error - Unable to update admin password", $!)
        end
      else
        error_message("Error","Server not running. Press refresh")
      end
    end
    @ops_server['Admin_Password_Button2'] = FXButton.new(@frame3g, "", :opts => BUTTON_TOOLBAR)
    @ops_server['Admin_Password_Button2'].icon = @magnifier
    @ops_server['Admin_Password_Button2'].tipText = "Show Admin Password"
    @ops_server['Admin_Password_Button2'].connect(SEL_COMMAND) do
      dialog = EC2_ShowPasswordDialog.new(@ec2_main,"Admin Password",@ops_server['Admin_Password'].text)
      dialog.execute
    end
    #
    # azure frame
    #
    @frame4 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame4.hide()
   # TODO: screen fields for azure frame
   #       vm.cloud_service_name = "cool-vm"
   #       vm.status = "ReadyRole"
   #       vm.ipaddress = "123.45.67.89"
   #       vm.vm_name = "cool-vm"
   #       vm.udp_endpoints = []
   #       vm.hostname = "cool-vm"
   #       vm.deployment_name = "cool-vm"
   #       vm.deployment_status = "Running"
   #       vm.tcp_endpoints = [
   #         {"Name"=>"http", "Vip"=>"123.45.67.89", "PublicPort"=>"80", "LocalPort"=>"80"},
   #         {"Name"=>"SSH", "Vip"=>"123.45.67.89", "PublicPort"=>"22", "LocalPort"=>"22"}
   #       ]
   #       vm.role_size = "Medium"
   #       vm.os_type = "Linux"
   #       vm.disk_name = "cool-vm-cool-vm-0-20130207005053"
   #       vm.virtual_network_name = ""
   #       vm.image = "ImageName"
    #FXLabel.new(@frame4, "Cloud Service Name" )
    #@azure_server['cloud_service_name'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Status" )
    #@azure_server['status'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "IP Address" )
    #@azure_server['ipaddress'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "VM Name" )
    #@azure_server['vm_name'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "URIs" )
    #@azure_server['uris'] = FXTable.new(@frame4,:height => 120, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    #@azure_server['uris'].connect(SEL_COMMAND) do |sender, sel, which|
    #  @cfy_uris_curr_row = which.row
    #  @azure_server['uris'].selectRow(@cfy_uris_curr_row)
    #end
    #(@azure_server['uris'].columnHeader).connect(SEL_COMMAND) do |sender, sel, which|
    #end
    #panel4a = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
    #FXLabel.new(panel4a, " ",:opts => LAYOUT_LEFT )
    #@cfy_uris_create_button = FXButton.new(panel4a, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_uris_create_button.icon = @create
    #@cfy_uris_create_button.tipText = "  Map URI  "
    #@cfy_uris_create_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  name = @azure_server['name'].text
    #  dialog = CFY_UriEditDialog.new(@ec2_main,name)
    #  dialog.execute
    #  if dialog.saved
    #    cfy_refresh(@appname)
    #  end
    #end
    #@cfy_uris_delete_button = FXButton.new(panel4a, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_uris_delete_button.icon = @delete
    #@cfy_uris_delete_button.tipText = "  Unmap URI  "
    #@cfy_uris_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  if @cfy_uris_curr_row == nil
    #    error_message("No URI selected","No URI selected to unset")
    #  else
    #    name = @azure_server['name'].text
    #    var_name =  @azure_server['uris'].getItemText(@cfy_uris_curr_row,0)
    #    dialog = CFY_UriEditDialog.new(@ec2_main,name,"unmap",var_name)
    #    dialog.execute
    #    if dialog.saved
    #      cfy_refresh(@appname)
    #    end
    #  end
    #end
    #@cfy_uris_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #
    #FXLabel.new(@frame4, "Instances" )
    #panel4e = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
    #@azure_server['instances'] =  FXTextField.new(panel4e, 25, nil, 0, :opts => FRAME_SUNKEN)
    #@cfy_instances_edit_button = FXButton.new(panel4e, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_instances_edit_button.icon = @edit
    #@cfy_instances_edit_button.tipText = "  Set Instances  "
    #@cfy_instances_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  name = @azure_server['name'].text
    #  parm = @azure_server['instances'].text
    #  dialog = CFY_InstancesEditDialog.new(@ec2_main,name,parm)
    #  if dialog.saved
    #    cfy_refresh(@appname)
    #  end
    #end
    #@cfy_instances_edit_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Running Instances" )
    #@azure_server['runningInstances'] = FXTextField.new(@frame4, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Memory" )
    #panel4f = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
    #@azure_server['memory'] = FXTextField.new(panel4f, 25, nil, 0, :opts => FRAME_SUNKEN)
    #@cfy_memory_edit_button = FXButton.new(panel4f, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_memory_edit_button.icon = @edit
    #@cfy_memory_edit_button.tipText = "  Set Memory Size  "
    #@cfy_memory_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  name = @azure_server['name'].text
    #  parm = @azure_server['memory'].text
    #  dialog = CFY_MemorySizeEditDialog.new(@ec2_main,name,parm)
    #  if dialog.saved
    #    cfy_refresh(@appname)
    #  end
    #end
    #@cfy_memory_edit_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Disk" )
    #@azure_server['disk'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "FDS" )
    #@azure_server['fds'] = FXTextField.new(@frame4, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Services" )
    #@azure_server['services'] = FXTable.new(@frame4,:height => 120, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    #@azure_server['services'].connect(SEL_COMMAND) do |sender, sel, which|
    #  @cfy_services_curr_row = which.row
    #  @azure_server['services'].selectRow(@cfy_services_curr_row)
    #end
    #(@azure_server['services'].columnHeader).connect(SEL_COMMAND) do |sender, sel, which|
    #end
    #panel4c = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
    #FXLabel.new(panel4c, " ",:opts => LAYOUT_LEFT )
    #@cfy_services_create_button = FXButton.new(panel4c, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_services_create_button.icon = @create
    #@cfy_services_create_button.tipText = "  Bind Service  "
    #@cfy_services_create_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  name = @azure_server['name'].text
    #  dialog = CFY_ServiceEditDialog.new(@ec2_main,name)
    #  dialog.execute
    #  if dialog.saved
    #    cfy_refresh(@appname)
    #  end
    #end
    #@cfy_services_delete_button = FXButton.new(panel4c, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_services_delete_button.icon = @delete
    #@cfy_services_delete_button.tipText = "  Unbind Service  "
    #@cfy_services_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  if @cfy_services_curr_row == nil
    #    error_message("No Service selected","No Service selected to unbind")
    #  else
    #    name = @azure_server['name'].text
    #    var_name =  @azure_server['services'].getItemText(@cfy_services_curr_row,0)
    #    dialog = CFY_ServiceEditDialog.new(@ec2_main,name,"unbind",var_name)
    #    dialog.execute
    #    if dialog.saved
    #      cfy_refresh(@appname)
    #    end
    #  end
    #end
    #@cfy_services_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #FXLabel.new(@frame4, "Version" )
    #@azure_server['version'] = FXTextField.new(@frame4, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    #FXLabel.new(@frame4, "" )
    #FXLabel.new(@frame4, "Env" )
    #@azure_server['env'] = FXTable.new(@frame4,:height => 180, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    #@azure_server['env'].connect(SEL_COMMAND) do |sender, sel, which|
    #  @cfy_env_curr_row = which.row
    #  @azure_server['env'].selectRow(@cfy_env_curr_row)
    #end
    #(@azure_server['env'].columnHeader).connect(SEL_COMMAND) do |sender, sel, which|
    #end
    #panel4d = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
    #FXLabel.new(panel4d, " ",:opts => LAYOUT_LEFT )
    #@cfy_env_create_button = FXButton.new(panel4d, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_env_create_button.icon = @create
    #@cfy_env_create_button.tipText = "  Set Environment Variable  "
    #@cfy_env_create_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  name = @azure_server['name'].text
    #  dialog = CFY_EnvEditDialog.new(@ec2_main,name)
    #  dialog.execute
    #  if dialog.saved
    #    cfy_refresh(@appname)
    #  end
    #end
    #@cfy_env_create_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #@cfy_env_edit_button = FXButton.new(panel4d, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_env_edit_button.icon = @modify
    #@cfy_env_edit_button.tipText = "  Edit Environment Variable  "
    #@cfy_env_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  if @cfy_env_curr_row == nil
    #    error_message("No Environment Variable selected","No Environment Variable selected to edit")
    #  else
    #    name = @azure_server['name'].text
    #    var_name =  @azure_server['env'].getItemText(@cfy_env_curr_row,0)
    #    dialog = CFY_EnvEditDialog.new(@ec2_main,name,"",var_name)
    #    dialog.execute
    #    if dialog.saved
    #      cfy_refresh(@appname)
    #    end
    #  end
    #end
    #@cfy_env_edit_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #@cfy_env_delete_button = FXButton.new(panel4d, " ",:opts => BUTTON_TOOLBAR)
    #@cfy_env_delete_button.icon = @delete
    #@cfy_env_delete_button.tipText = "  UnSet Environment Variable  "
    #@cfy_env_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
    #  if @cfy_env_curr_row == nil
    #    error_message("No Environment Variable selected","No Environment Variable selected to unset")
    #  else
    #    name = @azure_server['name'].text
    #    var_name =  @azure_server['env'].getItemText(@cfy_env_curr_row,0)
    #    dialog = CFY_EnvEditDialog.new(@ec2_main,name,"unset",var_name)
    #    dialog.execute
    #    if dialog.saved
    #      cfy_refresh(@appname)
    #    end
    #  end
    #end
    #@cfy_env_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
    #  sender.enabled = true
    #end
    #FXLabel.new(@frame4, "Meta" )
    #@azure_server['meta'] = FXText.new(@frame4, :height => 100, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)
    #FXLabel.new(@frame4, "" )

    #
    # local server  frame
    #
    @frame5 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame5.hide()
    @loc_server['server_label'] = FXLabel.new(@frame5, "Server" )
    @loc_server['server_label'].tipText = "REQUIRED: The unique name in EC2Dream to identify the server."
    @loc_server['server'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame5, "" )
    @loc_server['address_label'] = FXLabel.new(@frame5, "Address" )
    @loc_server['address_label'].tipText = "REQUIRED: The IP Address or DNS name for SSH access to the server."
    @loc_server['address'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['address_port_label'] = FXLabel.new(@frame5, "Address Port" )
    @loc_server['address_port_label'].tipText = "OPTIONAL: The port to use for SSH Access.\nDEFAULT: 22"
    @loc_server['address_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "(Default 22)" )
    @loc_server['ssh_user_label'] = FXLabel.new(@frame5, "SSH User" )
    @loc_server['ssh_user_label'].tipText = "OPTIONAL: SSH User for SSH access to the server.\nFor Windows Server Remote Desktop user."
    @loc_server['ssh_user'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['ssh_password_label'] = FXLabel.new(@frame5, "SSH Password" )
    @loc_server['ssh_password_label'].tipText = "OPTIONAL: SSH password or Windows administrator password.\nNot required if using and SSH key."
    @loc_server['ssh_password'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['ssh_key_label'] = FXLabel.new(@frame5, "SSH key" )
    @loc_server['ssh_key_label'].tipText = "OPTIONAL: SSH Key for SSH access to the server."
    @loc_server['ssh_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
        @loc_server['ssh_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['ssh_key_button'].icon = @magnifier
    @loc_server['ssh_key_button'].tipText = "Browse..."
    @loc_server['ssh_key_button'].connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(@frame5, "Select pem file")
      if @loc_server['ssh_key'].text!=nil and  @loc_server['ssh_key'].text==""
        dialog.directory = @loc_server['ssh_key'].text
      end
      dialog.patternList = [
        "Pem Files (*.pem)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        @loc_server['ssh_key'].text = dialog.filename
      end
    end
    @loc_server['putty_key_label'] = FXLabel.new(@frame5, "Putty Key" )
    @loc_server['putty_key_label'].tipText = "OPTIONAL: Putty Key for Putty access to the server."
    @loc_server['putty_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @frame5g = FXHorizontalFrame.new(@frame5,LAYOUT_FILL_X, :padding => 0)
    @loc_server['putty_key_button'] = FXButton.new(@frame5g, "", :opts => BUTTON_TOOLBAR)
    @loc_server['putty_key_button'].icon = @magnifier
    @loc_server['putty_key_button'].tipText = "Browse..."
    @loc_server['putty_key_button'].connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(@frame5, "Select puttyfile")
      if @loc_server['putty_key'].text!=nil and  @loc_server['putty_key'].text==""
        dialog.directory = @loc_server['putty_key'].text
      end
      dialog.patternList = [
        "Pem Files (*.ppk)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        @loc_server['putty_key'].text = dialog.filename
      end
    end
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("mingw") != nil
      @loc_server['PUTTY_GENERATE_BUTTON'] = FXButton.new(@frame5g, "", :opts => BUTTON_TOOLBAR)
      @loc_server['PUTTY_GENERATE_BUTTON'].icon = @link
      @loc_server['PUTTY_GENERATE_BUTTON'].tipText = " PuTTYgen Key Generator "
      @loc_server['PUTTY_GENERATE_BUTTON'].connect(SEL_COMMAND) do
        dialog = EC2_GenerateKeyDialog.new(@ec2_main,"SSH_PRIVATE_KEY",@loc_server['ssh_key'].text)
        dialog.execute
      end
     # @settings['PUTTY_GENERATE_BUTTON'].connect(SEL_UPDATE) do |sender, sel, data|
     #   enable_if_env_set(sender)
     # end
    end

    @loc_server['windows_server_label'] = FXLabel.new(@frame5, "Windows Server" )
    @loc_server['windows_server_label'].tipText = "true or false. If true Remote Desktop will be used to access the server."
    @loc_server['windows_server'] = FXComboBox.new(@frame5, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @loc_server['windows_server'].numVisible = 2
    @loc_server['windows_server'].appendItem("true")
    @loc_server['windows_server'].appendItem("false")
    @loc_server['windows_server'].setCurrentItem(1)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Tunnelling - Bastion Host" )
    FXLabel.new(@frame5, "" )
    @loc_server['local_port_label'] = FXLabel.new(@frame5, "Local Port" )
    @loc_server['local_port_label'].tipText = "OPTIONAL: SSH port to use if different from default 22.\nTypically used when doing SSH Tunneling."
    @loc_server['local_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['bastion_host_label'] = FXLabel.new(@frame5, "Bastion Host" )
    @loc_server['bastion_host_label'].tipText = "OPTIONAL: IP address or DNS of bastion server for SSH Tunneling."
    @loc_server['bastion_host'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['bastion_port_label'] = FXLabel.new(@frame5, "Bastion Port" )
    @loc_server['bastion_port_label'].tipText = "OPTIONAL: SSH Port of Bastion Host"
    @loc_server['bastion_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['bastion_user_label'] = FXLabel.new(@frame5, "Bastion User" )
    @loc_server['bastion_user_label'].tipText = "OPTIONAL: SSH User for Bastion Host"
    @loc_server['bastion_user'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['bastion_password_label'] = FXLabel.new(@frame5, "Bastion Password" )
    @loc_server['bastion_password_label'].tipText = "OPTIONAL: SSH Password for Basion Host"
    @loc_server['bastion_password'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    @loc_server['bastion_ssh_key_label'] = FXLabel.new(@frame5, "Bastion SSH key" )
    @loc_server['bastion_ssh_key_label'].tipText = "OPTIONAL: SSH Key for Bastion Host"
    @loc_server['bastion_ssh_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['bastion_ssh_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['bastion_ssh_key_button'].icon = @magnifier
    @loc_server['bastion_ssh_key_button'].tipText = "Browse..."
    @loc_server['bastion_ssh_key_button'].connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(@frame5, "Select pem file")
      if @loc_server['bastion_ssh_key'].text!=nil and  @loc_server['bastion_ssh_key'].text==""
        dialog.directory = @loc_server['bastion_ssh_key'].text
      end
      dialog.patternList = [
        "Pem Files (*.pem)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        @loc_server['bastion_ssh_key'].text = dialog.filename
      end
    end
    @loc_server['bastion_putty_key_label'] = FXLabel.new(@frame5, "Bastion Putty Key" )
    @loc_server['bastion_putty_key_label'].tipText = "OPTIONAL: Putty key for Bastion Host."
    @loc_server['bastion_putty_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['bastion_putty_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['bastion_putty_key_button'].icon = @magnifier
    @loc_server['bastion_putty_key_button'].tipText = "Browse..."
    @loc_server['bastion_putty_key_button'].connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(@frame5, "Select pem file")
      if @loc_server['bastion_putty_key'].text!=nil and  @loc_server['bastion_putty_key'].text==""
        dialog.directory = @loc_server['bastion_putty_key'].text
      end
      dialog.patternList = [
        "Pem Files (*.ppk)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        @loc_server['bastion_putty_key'].text = dialog.filename
      end
    end
    #
    # google frame
    #
    @frame6 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame6.hide()
    FXLabel.new(@frame6, "Name" )
    @frame6s = FXHorizontalFrame.new(@frame6,LAYOUT_FILL_X, :padding => 0)
    @google_server['Name'] = FXTextField.new(@frame6s, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Instance ID" )
    @frame6t = FXHorizontalFrame.new(@frame6,LAYOUT_FILL_X, :padding => 0)
    @google_server['Instance_ID'] = FXTextField.new(@frame6t, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "State" )
    @frame6j = FXHorizontalFrame.new(@frame6,LAYOUT_FILL_X, :padding => 0)
    @google_server['State'] = FXTextField.new(@frame6j, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    @google_server['State'].font = FXFont.new(@ec2_main.app, "Arial", 8, :weight => FXFont::ExtraBold)
    FXLabel.new(@frame6j, "       Launch Time" )
    @google_server['Launch_Time'] = FXTextField.new(@frame6j, 30, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )

    FXLabel.new(@frame6, "Tags" )
    @google_server['Tags'] = FXTextField.new(@frame6, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Kernel" )
    @google_server['Kernel'] = FXTextField.new(@frame6, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Machine Type" )
    @google_server['Flavor'] = FXTextField.new(@frame6, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Zone")
    @google_server['Availability_Zone'] = FXTextField.new(@frame6, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Scheduling")
    @google_server['Scheduling'] = FXTextField.new(@frame6, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
      @google_server['SSH_Private_Key_label'] = FXLabel.new(@frame6,"SSH Private Key" )
      @google_server['SSH_Private_Key_label'].tipText = "OPTIONAL: SSH Key for SSH access to the server.\nDEFAULT: defaults to value specified in Environment tab."
      @google_server['SSH_Private_Key'] = FXTextField.new(@frame6, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @google_server['SSH_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @google_server['Instance_ID'].text
        @ec2_ssh_private_key[instance_id] = @google_server['SSH_Private_Key'].text
        @ec2_main.launch.ops_put('SSH_Private_Key',@google_server['SSH_Private_Key'].text)
        @ec2_main.launch.ops_save
      end
      @google_server['SSH_Private_Key_Button'] = FXButton.new(@frame6, "", :opts => BUTTON_TOOLBAR)
      @google_server['SSH_Private_Key_Button'].icon = @magnifier
      @google_server['SSH_Private_Key_Button'].tipText = "Browse..."
      @google_server['SSH_Private_Key_Button'].connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(@frame6, "Select pem file")
        dialog.patternList = [
          "Pem Files (*.pem)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
          @google_server['SSH_Private_Key'].text = dialog.filename
          instance_id = @google_server['Instance_ID'].text
          @ec2_ssh_private_key[instance_id] = @google_server['SSH_Private_Key'].text
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('SSH_Private_Key',@google_server['SSH_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    else
      @google_server['Putty_Private_Key_label'] = FXLabel.new(@frame6, "Putty Private Key" )
      @google_server['Putty_Private_Key_label'].tipText = "OPTIONAL: Putty Key for Putty access to the server."
      @google_server['Putty_Private_Key'] = FXTextField.new(@frame6, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @google_server['Putty_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @google_server['Instance_ID'].text
        @putty_private_key[instance_id] = @google_server['Putty_Private_Key'].text
        if @ec2_main.launch.loaded == true
          @ec2_main.launch.ops_put('Putty_Private_Key',@google_server['Putty_Private_Key'].text)
          @ec2_main.launch.save
        end
      end
      @google_server['Putty_Private_Key_Button'] = FXButton.new(@frame6, "", :opts => BUTTON_TOOLBAR)
      @google_server['Putty_Private_Key_Button'].icon = @magnifier
      @google_server['Putty_Private_Key_Button'].tipText = "Browse..."
      @google_server['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(@frame6, "Select ppk file")
        dialog.patternList = [
          "Pem Files (*.ppk)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
          @google_server['Putty_Private_Key'].text = dialog.filename
          instance_id = @google_server['Instance_ID'].text
          @putty_private_key[instance_id] = @google_server['Putty_Private_Key'].text
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('Putty_Private_Key',@google_server['Putty_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    end
    @google_server['EC2_SSH_User_label'] = FXLabel.new(@frame6, "SSH/Win Admin User" )
    @google_server['EC2_SSH_User_label'].tipText = "OPTIONAL: SSH User for SSH access to the server.\nFor Windows Server Remote Desktop user.\nDEFAULT: defaults to value specified in Environment tab."
    @google_server['EC2_SSH_User'] = FXTextField.new(@frame6, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @google_server['EC2_SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.ops_put('EC2_SSH_User',data)
        @ec2_main.launch.save
      end
    end
    FXLabel.new(@frame6, "" )
    @google_server['Admin_Password_label'] = FXLabel.new(@frame6, "SSH/Win Admin Password" )
    @google_server['Admin_Password_label'].tipText = "OPTIONAL: SSH User password or Windows Administrator user password for use with Remote Desktop."
    @google_server['Admin_Password'] = FXTextField.new(@frame6, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_PASSWD)
    @google_server['Admin_Password'].connect(SEL_COMMAND) do |sender, sel, data|
      instance_id = @google_server['Instance_ID'].text
      @google_admin_pw[instance_id] = data
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.ops_put('Admin_Password',data)
        @ec2_main.launch.ops_save
      end
    end
    @frame6g = FXHorizontalFrame.new(@frame6,LAYOUT_FILL_X, :padding => 0)
    @google_server['Admin_Password_Button'] = FXButton.new(@frame6g, "", :opts => BUTTON_TOOLBAR)
    @google_server['Admin_Password_Button'].icon = @key
    @google_server['Admin_Password_Button'].tipText = "Change Admin Password"
    @google_server['Admin_Password_Button'].connect(SEL_COMMAND) do
      if loaded
        begin
          instance_id = @google_server['Instance_ID'].text
          dialog = EC2_InstanceAdminPasswordDialog.new(@ec2_main,instance_id)
          dialog.execute
          if dialog.updated
            pw = dialog.selected
            @google_server['Admin_Password'].text = pw
            instance_id = @google_server['Instance_ID'].text
            @google_admin_pw[instance_id] = pw
            if @ec2_main.launch.loaded == true
              @ec2_main.launch.ops_put('Admin_Password',pw)
              @ec2_main.launch.ops_save
            end
            FXMessageBox.information(@ec2_main,MBOX_OK,"Admin Password","Admin password #{pw} saved")
          end
        rescue
          error_message("Error - Unable to update admin password", $!)
        end
      else
        error_message("Error","Server not running. Press refresh")
      end
    end
    @google_server['Admin_Password_Button2'] = FXButton.new(@frame6g, "", :opts => BUTTON_TOOLBAR)
    @google_server['Admin_Password_Button2'].icon = @magnifier
    @google_server['Admin_Password_Button2'].tipText = "Show Admin Password"
    @google_server['Admin_Password_Button2'].connect(SEL_COMMAND) do
      dialog = EC2_ShowPasswordDialog.new(@ec2_main,"Admin Password",@google_server['Admin_Password'].text)
      dialog.execute
    end
    @google_server['Public_Addr_label'] = FXLabel.new(@frame6, "IP Addr" )
    @google_server['Public_Addr_label'].tipText = "Public IP used as address for ssh."
    @google_server['Public_Addr'] = FXTextField.new(@frame6, 40, nil, 0, :opts => FRAME_SUNKEN)
    @google_server['Public_Addr'].connect(SEL_COMMAND) do  |sender, sel, data|
      instance_id = @google_server['Instance_ID'].text
      @google_public_addr[instance_id] = data
      #@ec2_main.launch.ops_put('Public_Addr',data)
      #@ec2_main.launch.save
    end
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Can Ip Forward" )
    @google_server['Can_Ip_Forward'] = FXTextField.new(@frame6, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Networks" )
    @google_server['Addresses'] =  FXText.new(@frame6, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @google_server['Addresses'].setVisibleRows(5)
    @google_server['Addresses'].setText("")
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Disks" )
    @google_server['Disks'] =  FXText.new(@frame6, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @google_server['Disks'].setVisibleRows(5)
    @google_server['Disks'].setText("")
    FXLabel.new(@frame6, "" )
    FXLabel.new(@frame6, "Metadata" )
    @google_server['Metadata'] =  FXText.new(@frame6, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @google_server['Metadata'].setVisibleRows(10)
    @google_server['Metadata'].setText("")
    FXLabel.new(@frame6, "" )

    #
    # softlayer frame
    #
    @frame7 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame7.hide()
    FXLabel.new(@frame7, "Name" )
    @softlayer_server['Name'] = FXTextField.new(@frame7, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "ID" )
    @softlayer_server['Instance_ID'] = FXTextField.new(@frame7, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Fqdn" )
    @softlayer_server['Fqdn'] = FXTextField.new(@frame7, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Create Time" )
    @softlayer_server['Created_At'] = FXTextField.new(@frame7, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )

    FXLabel.new(@frame7, "Tags" )
    @softlayer_server['Tags'] = FXTextField.new(@frame7, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Image_Id" )
    @softlayer_server['Image_Id'] = FXTextField.new(@frame7, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Machine Type" )
    @softlayer_server['Flavor_Id'] = FXTextField.new(@frame7, 25, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "OS Code")
    @softlayer_server['Os_Code'] = FXTextField.new(@frame7, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Key Pairs")
    @softlayer_server['Key_Pairs'] = FXTextField.new(@frame7, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
      @softlayer_server['SSH_Private_Key_label'] = FXLabel.new(@frame7,"SSH Private Key" )
      @softlayer_server['SSH_Private_Key_label'].tipText = "OPTIONAL: SSH Key for SSH access to the server.\nDEFAULT: defaults to value specified in Environment tab."
      @softlayer_server['SSH_Private_Key'] = FXTextField.new(@frame7, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @softlayer_server['SSH_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @softlayer_server['ID'].text
        @ec2_ssh_private_key[instance_id] = @softlayer_server['SSH_Private_Key'].text
        @ec2_main.launch.ops_put('SSH_Private_Key',@softlayer_server['SSH_Private_Key'].text)
        @ec2_main.launch.ops_save
      end
      @softlayer_server['SSH_Private_Key_Button'] = FXButton.new(@frame7, "", :opts => BUTTON_TOOLBAR)
      @softlayer_server['SSH_Private_Key_Button'].icon = @magnifier
      @softlayer_server['SSH_Private_Key_Button'].tipText = "Browse..."
      @softlayer_server['SSH_Private_Key_Button'].connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(@frame7, "Select pem file")
        dialog.patternList = [
          "Pem Files (*.pem)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
          @softlayer_server['SSH_Private_Key'].text = dialog.filename
          instance_id = @softlayer_server['Instance_ID'].text
          @ec2_ssh_private_key[instance_id] = @softlayer_server['SSH_Private_Key'].text
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('SSH_Private_Key',@softlayer_server['SSH_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    else
      @softlayer_server['Putty_Private_Key_label'] = FXLabel.new(@frame7, "Putty Private Key" )
      @softlayer_server['Putty_Private_Key_label'].tipText = "OPTIONAL: Putty Key for Putty access to the server."
      @softlayer_server['Putty_Private_Key'] = FXTextField.new(@frame7, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      @softlayer_server['Putty_Private_Key'].connect(SEL_COMMAND) do
        instance_id = @softlayer_server['Instance_ID'].text
        @putty_private_key[instance_id] = @softlayer_server['Putty_Private_Key'].text
        if @ec2_main.launch.loaded == true
          @ec2_main.launch.ops_put('Putty_Private_Key',@softlayer_server['Putty_Private_Key'].text)
          @ec2_main.launch.save
        end
      end
      @softlayer_server['Putty_Private_Key_Button'] = FXButton.new(@frame7, "", :opts => BUTTON_TOOLBAR)
      @softlayer_server['Putty_Private_Key_Button'].icon = @magnifier
      @softlayer_server['Putty_Private_Key_Button'].tipText = "Browse..."
      @softlayer_server['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(@frame7, "Select ppk file")
        dialog.patternList = [
          "Pem Files (*.ppk)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
          @softlayer_server['Putty_Private_Key'].text = dialog.filename
          instance_id = @softlayer_server['Instance_ID'].text
          @putty_private_key[instance_id] = @softlayer_server['Putty_Private_Key'].text
          if @ec2_main.launch.loaded == true
            @ec2_main.launch.ops_put('Putty_Private_Key',@softlayer_server['Putty_Private_Key'].text)
            @ec2_main.launch.save
          end
        end
      end
    end
    @softlayer_server['EC2_SSH_User_label'] = FXLabel.new(@frame7, "SSH/Win Admin User" )
    @softlayer_server['EC2_SSH_User_label'].tipText = "OPTIONAL: SSH User for SSH access to the server.\nFor Windows Server Remote Desktop user.\nDEFAULT: defaults to value specified in Environment tab."
    @softlayer_server['EC2_SSH_User'] = FXTextField.new(@frame7, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @softlayer_server['EC2_SSH_User'].connect(SEL_COMMAND) do |sender, sel, data|
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.softlayer_put('EC2_SSH_User',data)
        @ec2_main.launch.save
      end
    end
    FXLabel.new(@frame7, "" )
    @softlayer_server['Admin_Password_label'] = FXLabel.new(@frame7, "SSH/Win Admin Password" )
    @softlayer_server['Admin_Password_label'].tipText = "OPTIONAL: SSH User password or Windows Administrator user password for use with Remote Desktop."
    @softlayer_server['Admin_Password'] = FXTextField.new(@frame7, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_PASSWD)
    @softlayer_server['Admin_Password'].connect(SEL_COMMAND) do |sender, sel, data|
      instance_id = @softlayer_server['Instance_ID'].text
      @softlayer_admin_pw[instance_id] = data
      if @ec2_main.launch.loaded == true
        @ec2_main.launch.ops_put('Admin_Password',data)
        @ec2_main.launch.ops_save
      end
    end
    @frame7g = FXHorizontalFrame.new(@frame7,LAYOUT_FILL_X, :padding => 0)
    @softlayer_server['Admin_Password_Button'] = FXButton.new(@frame7g, "", :opts => BUTTON_TOOLBAR)
    @softlayer_server['Admin_Password_Button'].icon = @key
    @softlayer_server['Admin_Password_Button'].tipText = "Change Admin Password"
    @softlayer_server['Admin_Password_Button'].connect(SEL_COMMAND) do
      if loaded
        begin
          instance_id = @softlayer_server['Instance_ID'].text
          dialog = EC2_InstanceAdminPasswordDialog.new(@ec2_main,instance_id)
          dialog.execute
          if dialog.updated
            pw = dialog.selected
            @softlayer_server['Admin_Password'].text = pw
            instance_id = @softlayer_server['Instance_ID'].text
            @softlayer_admin_pw[instance_id] = pw
            if @ec2_main.launch.loaded == true
              @ec2_main.launch.ops_put('Admin_Password',pw)
              @ec2_main.launch.ops_save
            end
            FXMessageBox.information(@ec2_main,MBOX_OK,"Admin Password","Admin password #{pw} saved")
          end
        rescue
          error_message("Error - Unable to update admin password", $!)
        end
      else
        error_message("Error","Server not running. Press refresh")
      end
    end
    @softlayer_server['Admin_Password_Button2'] = FXButton.new(@frame7g, "", :opts => BUTTON_TOOLBAR)
    @softlayer_server['Admin_Password_Button2'].icon = @magnifier
    @softlayer_server['Admin_Password_Button2'].tipText = "Show Admin Password"
    @softlayer_server['Admin_Password_Button2'].connect(SEL_COMMAND) do
      dialog = EC2_ShowPasswordDialog.new(@ec2_main,"Admin Password",@softlayer_server['Admin_Password'].text)
      dialog.execute
    end
    @softlayer_server['Public_IP_label'] = FXLabel.new(@frame7, "Public IP Addr" )
    @softlayer_server['Public_IP_label'].tipText = "Public IP used as address for ssh."
    @softlayer_server['Public_IP_Address'] = FXTextField.new(@frame7, 40, nil, 0, :opts => FRAME_SUNKEN)
    @softlayer_server['Public_IP_Address'].connect(SEL_COMMAND) do  |sender, sel, data|
      instance_id = @softlayer_server['Instance_ID'].text
      @softlayer_public_addr[instance_id] = data
      #@ec2_main.launch.ops_put('Public_IP_Address',data)
      #@ec2_main.launch.save
    end
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Private IP" )
    @softlayer_server['Private_IP_Address'] = FXTextField.new(@frame7, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Networks" )
    @softlayer_server['Network_Components'] =  FXText.new(@frame7, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @softlayer_server['Network_Components'].setVisibleRows(5)
    @softlayer_server['Network_Components'].setText("")
    FXLabel.new(@frame7, "" )
    FXLabel.new(@frame7, "Disks" )
    @softlayer_server['Disks'] =  FXText.new(@frame7, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @softlayer_server['Disks'].setVisibleRows(5)
    @softlayer_server['Disks'].setText("")
    FXLabel.new(@frame7, "" )
    #FXLabel.new(@frame7, "Provision_Script" )
    #@softlayer_server['Provision_Script'] =  FXTextField.new(@frame7, 40, nil, 0, :opts => FRAME_SUNKEN)
    #FXLabel.new(@frame7, "" )
  end

  def run_scp
    server = currentServer
    if @type == "ops"
      user = @ec2_main.launch.ops_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @ops_server['Public_Addr'].text
      password = @ops_server['Admin_Password'].text
      local_port = nil  # not added yet
    elsif @type == "google"
      user = @ec2_main.launch.google_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @google_server['Public_Addr'].text
      password = ""
      local_port = nil  # not added yet
    elsif @type == "softlayer"
      user = @softlayer_server['EC2_SSH_User'].text
      #user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @softlayer_server['Public_IP_Address'].text
      address = @softlayer_server['Private_IP_Address'].text if address == nil or address == ""
      password = @softlayer_server['Admin_Password'].text
      local_port = nil  # not added yet
    else
      address = @server['Public_IP'].text
      address = @server['Private_IP'].text if address == nil or address == ""
      user = @ec2_main.launch.get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      password =""
      local_port = @server['Local_Port'].text
    end
    putty_key = get_ppk
    private_key = get_pk
    puts "scp #{server}, #{address}, #{user}, #{private_key}, #{putty_key}, #{password}, #{local_port}"
    scp(server, address, user, private_key, putty_key, password, local_port)
  end

  def run_ssh
    server = currentServer
    if @type == "ops"
      user = @ec2_main.launch.ops_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @ops_server['Public_Addr'].text
      password = @ops_server['Admin_Password'].text
      local_port = nil  # not added yet
    elsif @type == "google"
      address = @google_server['Public_Addr'].text
      user = @ec2_main.launch.google_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      password = ""
      local_port = nil  # not added yet
    elsif @type == "softlayer"
      user = @softlayer_server['EC2_SSH_User'].text
      #user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @softlayer_server['Public_IP_Address'].text
      address = @softlayer_server['Private_IP_Address'].text if address == nil or address == ""
      password = @softlayer_server['Admin_Password'].text
      local_port = nil  # not added yet
    else
      address = @server['Public_IP'].text
      address = @server['Private_IP'].text if address == nil or address == ""
      user = @ec2_main.launch.get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      password = ""
      local_port = @server['Local_Port'].text
    end
    putty_key = get_ppk
    private_key = get_pk
    ssh(server, address, user, private_key, putty_key, password, local_port)
  end

  def run_ssh_tunnel
    puts "Server.run_ssh_tunnel"
    server = currentServer
    instance_id = @server['Instance_ID'].text

    r = {}
    r = @bastion[instance_id] if @bastion[instance_id] != nil
    if @type == "ops"
      user = @ec2_main.launch.ops_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @ops_server['Public_Addr'].text
      password = @ops_server['Admin_Password'].text
      local_port = nil   # not added yet
      address_port = "22"
    elsif @type == "google"
      user = @ec2_main.launch.google_get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @google_server['Public_Addr'].text
      password = ""
      local_port = nil   # not added yet
      address_port = "22"
    else
      #address = @server['Public_IP'].text
      address = @server['Private_IP'].text if address == nil or address == ""
      instance_id = @server['Instance_ID'].text
      user = @ec2_main.launch.get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      local_port = @server['Local_Port'].text
      password = ""
      address_port = "22"
      if @server['Platform'].text == "windows"
        address_port = "3389"
      end
    end
    putty_key = get_ppk
    private_key = get_pk
    puts "ssh_tunnel #{server}, #{address}, #{user}, #{private_key}, #{putty_key}, #{password}, #{address_port}, #{local_port}, #{r}"
    ssh_tunnel(server, address, user, private_key, putty_key, password, address_port, local_port, r['bastion_host'], r['bastion_port'],r['bastion_user'], r['bastion_ssh_key'], r['bastion_putty_key'])
  end

  def run_remote_desktop
    server = currentServer
    instance_id = @server['Instance_ID'].text
    r = {}
    r = @bastion[instance_id] if @bastion[instance_id] != nil
    if @type == "ops"
      user = @ec2_main.launch.ops_get("SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      address = @ops_server['Public_Addr'].text
      pw = @ops_server['Admin_Password'].text
      local_port = nil   # not added yet
    elsif @type == "google"
      return   # no windows on google
    else
      address = @server['Public_IP'].text
      user = @ec2_main.launch.get("EC2_SSH_User")
      user = @ec2_main.settings.get('EC2_SSH_USER') if user == nil or user == ''
      pw = @server['Win_Admin_Password'].text
      local_port = @server['Local_Port'].text
    end
    if pw != nil and pw != ""
      remote_desktop(server, pw, user, "3389", local_port, r['bastion_host'], r['bastion_port'],r['bastion_user'], r['bastion_password'])
    else
      error_message("Error","No Admin Password")
    end
  end

#  def get_chef_node
#   instance_id = @server['Instance_ID'].text
#    if @ec2_chef_node[instance_id] != nil and @ec2_chef_node[instance_id] != ""
#      cn =  @ec2_chef_node[instance_id]
#    else
#      cn = @ec2_main.launch.get('Chef_Node')
#      if cn == nil or cn == ""
#        cn = "default-server"
#      end
#    end
#    puts "chef_node #{cn}"
#    return cn
#  end

  def get_pk
    pk = ""
    if @type == "ec2"
      instance_id = @server['Instance_ID'].text
      if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
        pk =  @ec2_ssh_private_key[instance_id]
      else
        pk = @ec2_main.launch.get('EC2_SSH_Private_Key')
        if pk == nil or pk == ""
          kp = @ec2_main.settings.get('AMAZON_KEYPAIR')
          if kp == nil or kp == "" or kp == @server['Key_Name'].text
             pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
          end
        end
      end
    elsif @type == "ops"
      instance_id = @ops_server['Instance_ID'].text
      if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
        pk =  @ec2_ssh_private_key[instance_id]
      else
        pk = @ec2_main.launch.ops_get('EC2_SSH_Private_Key')
        if pk == nil or pk == ""
          pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
        end
      end
    elsif @type == "softlayer"
      instance_id = @softlayer_server['Instance_ID'].text
      if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
        pk =  @ec2_ssh_private_key[instance_id]
      else
        #pk = @ec2_main.launch.google_get('EC2_SSH_Private_Key')
        #if pk == nil or pk == ""
          pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
        #end
      end
    elsif @type == "google"
      instance_id = @google_server['Instance_ID'].text
      if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
        pk =  @ec2_ssh_private_key[instance_id]
      else
        pk = @ec2_main.launch.google_get('EC2_SSH_Private_Key')
        if pk == nil or pk == ""
          pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
        end
      end
    end
    return pk
  end

  def get_ppk
    pk = ""
    if @type == "ec2"
      instance_id = @server['Instance_ID'].text
      if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
        pk =  @putty_private_key[instance_id]
      else
        pk = @ec2_main.launch.get('Putty_Private_Key')
        if pk == nil or pk == ""
          pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
        end
      end
    elsif @type == "ops"
      instance_id = @ops_server['Instance_ID'].text
      if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
        pk =  @putty_private_key[instance_id]
      else
        pk = @ec2_main.launch.ops_get('Putty_Private_Key')
        if pk == nil or pk == ""
          pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
        end
      end
    elsif @type == "softlayer"
      instance_id = @ops_server['Instance_ID'].text
      if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
        pk =  @putty_private_key[instance_id]
      else
        #pk = @ec2_main.launch.ops_get('Putty_Private_Key')
        #if pk == nil or pk == ""
          pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
        #end
      end
    elsif @type == "google"
      instance_id = @google_server['Instance_ID'].text
      if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
        pk =  @putty_private_key[instance_id]
      else
        pk = @ec2_main.launch.google_get('Putty_Private_Key')
        if pk == nil or pk == ""
          pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
        end
      end
    end
    return pk
  end

  def currentInstance
    if @type == "ec2"
      return @server['Instance_ID'].text
    elsif @type == "ops"
      return @ops_server['Instance_ID'].text
    elsif @type == "google"
      return @google_server['Instance_ID'].text
    elsif @type == "softlayer"
      return @softlayer_server['Instance_ID'].text
    else
      return ""
    end
  end


  def currentServer
    if @type == "ec2"
      #if @server['Public_DSN'].text != nil and @server['Public_DSN'].text != ""
      #  return @server['Public_DSN'].text
      if @server['Public_IP'].text != nil and @server['Public_IP'].text != ""
        return @server['Public_IP'].text        
      else
        return @server['Private_IP'].text
      end
    elsif @type == "ops"
      return @ops_server['Public_Addr'].text
    elsif @type == "google"
      return @google_server['Name'].text
    elsif @type == "softlayer"
      if @softlayer_server['Public_IP_Address'].text != nil and @softlayer_server['Public_IP_Address'].text != ""
        return @softlayer_server['Public_IP_Address'].text
      else
        return @softlayer_server['Private_IP_Address'].text
      end
    else
      return ""
    end
  end

  def instance_group(i)
    return @ec2_main.serverCache.instance_group(i)
  end

  def load_server(server)
    sa = (server).split"/"
    if sa.size>1
      load(sa[sa.size-1])
    end
  end

  def loaded
    if @type == "ec2" and @server_status == "running"
      return true
    elsif @type == "ops" and @server_status.start_with?("ACTIVE")
      return true
    elsif @type == "google" and @server_status == "RUNNING"
      return true
    elsif @type == "softlayer" and @softlayer_server['Created_At'].text!=nil and @softlayer_server['Created_At'].text!=""
      return true
    elsif @type == "loc"
      return true
    else
      return false
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
    if loaded and ["ec2","ops","google","cfy","loc","softlayer","kit"].include? @type
      sender.enabled = true
    else
      sender.enabled = false
    end
  end

  def enable_if_server_loaded_or_pending(sender)
    if loaded or ["pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT","PROVISIONING","STAGING"].include? @server_status
      sender.enabled = true
    else
      sender.enabled = false
    end
  end

  def enable_if_ec2_server_loaded(sender)
    if loaded and (@type == "ec2" or @type == "ops" or @type == "google" or @type == "softlayer" or @type == "loc")
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

  def set_ec2dream_hostname
    ENV['EC2DREAM_HOSTNAME']=''
    if @type == "ec2"
      address = @server['Public_IP'].text
      address = @server['Private_IP'].text if address == nil or address == ""
      ENV['EC2DREAM_HOSTNAME']=address
    elsif @type == "ops"
      ENV['EC2DREAM_HOSTNAME'] = @ops_server['Public_Addr'].text if @ops_server['Public_Addr'].text != nil
    elsif @type == "google"
      ENV['EC2DREAM_HOSTNAME'] = @google_server['Public_Addr'].text if @google_server['Public_Addr'].text != nil
    elsif @type == "softlayer"
      ENV['EC2DREAM_HOSTNAME'] = @softlayer_server['Public_IP_Address'].text if @softlayer_server['Public_IP_Address'].text != nil
    elsif @type == "loc"
      ENV['EC2DREAM_HOSTNAME'] = @loc_server['address'].text if @loc_server['address'].text != nil
    end
  end
end

