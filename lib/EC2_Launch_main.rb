class EC2_Launch

  def initialize(owner)
        @ec2_main = owner
        @profile = ""
        @properties = {}
        @block_mapping = EC2_Block_Mapping.new
        @image_bm = EC2_Block_Mapping.new
        @as_bm = EC2_Block_Mapping.new
        @read_replica = Array.new
        @read_replica_curr_row = nil 
        @launch_loaded = false
        @type = ""
        @curr_item = ""
        @resource_tags = nil 
        @profile_type = "secgrp"
        @profile_folder = "launch"
        tab = FXTabItem.new(@ec2_main.tabBook, " Launch ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        #
	# buttons frame
	#
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@arrow_refresh = @ec2_main.makeIcon("arrow_refresh.png")
	@arrow_refresh.create
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Refresh Environment"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	    puts "server.refresh.connect"
	    @ec2_main.treeCache.refresh
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	@save_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@save = @ec2_main.makeIcon("disk.png")
	@save.create
	@save_button.icon = @save
	@save_button.tipText = "  Save Launch Profile  "
	@save_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "ec2"
	       save
	    elsif @type == "ops"
	       ops_save	       
	    elsif @type == "rds"
	       rds_save
	    elsif @type == "as"
	       as_save
	    end
	end
	@save_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_launch_loaded(sender)
	    if @type == "as"
	       if  @launch_loaded == true
	          sender.enabled = false
	       else
	          sender.enabled = true
	       end
	    end   
	end
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@kill = @ec2_main.makeIcon("kill.png")
	@kill.create
	@delete_button.icon = @kill
	@delete_button.tipText = " Delete Launch Profile "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "ec2"
	       delete
	    elsif @type == "ops"
	       ops_delete	       
	    elsif @type == "rds"
	       rds_delete
	    end
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_launch_loaded(sender)
	   if @type == "as"  
	      sender.enabled = false
	   end
	end
	
	@launch_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@rocket = @ec2_main.makeIcon("rocket.png")
	@rocket.create
	@rocketdb = @ec2_main.makeIcon("rocketdb.png")
	@rocketdb.create	
	@launch_button.icon = @rocket
	@launch_button.tipText = " Launch Server Instance "
	@launch_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "ec2"
	       if @launch['Spot_Price'].text == nil or @launch['Spot_Price'].text == ""
	          launch_instance
	       else
	          request_spot_instance
	       end
	    elsif @type == "ops"
               launch_ops_instance	       
	    elsif @type == "rds"
               launch_rds_instance
	    end		
	end
	@launch_button.connect(SEL_UPDATE) do |sender, sel, data|
         sender.enabled = false
	   if @type == "ec2" or @type == "ops"
            enable_if_launch_loaded(sender)
	      @launch_button.icon = @rocket
	      @launch_button.tipText = " Launch Server Instance "
	   elsif @type == "rds"
            enable_if_launch_loaded(sender)
	      @launch_button.icon =  @rocketdb
	      @launch_button.tipText = " Launch DBInstance "
	   end	   
	end
	@launch_snap_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@rocketdb_snap = @ec2_main.makeIcon("camera.png")
	@rocketdb_snap.create	
	@launch_snap_button.icon = @rocketdb_snap
	@launch_snap_button.tipText = " Restore DBInstance from Snapshot "
	@launch_snap_button.connect(SEL_COMMAND) do |sender, sel, data|
	    if @type == "rds"
	       if @rds_launch['DBSnapshot'].text == nil or @rds_launch['DBSnapshot'].text == ""
	          error_message("Error","No DBSnapshot specified") 
	       else
	          restore_rds_instance
	       end
	    end		
	    
	end
	@launch_snap_button.connect(SEL_UPDATE) do |sender, sel, data|
             if loaded and @type ==  "rds"
                 sender.enabled = true
             else
                 sender.enabled = false
             end 
	end
	
	@launch_restore_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@rocketdb_time = @ec2_main.makeIcon("clock.png")
	@rocketdb_time.create	
	@launch_restore_button.icon = @rocketdb_time
	@launch_restore_button.tipText = " Restore DBInstance To Point in Time "
	@launch_restore_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type ==  "rds"
            params = {} 
            params[:instance_class] = @rds_launch['DBInstanceClass'].text
            params[:endpoint_port] = @rds_launch['Port'].text
            params[:availability_zone] = @rds_launch['AvailabilityZone'].text
            if @rds_launch['MultiAZ'].itemCurrent?(0)
               params[:multi_az] = "true"
            end
            if @rds_launch['AutoMinorVersionUpgrade'].itemCurrent?(1)
               params[:auto_minor_version_upgrade] = "false"
            end
	    @dialog = RDS_RestoreTimeDialog.new(@ec2_main, @rds_launch['DBInstanceId'].text, params )
	    @dialog.execute
	    created = @dialog.created
	    if created == true 
	         r = @dialog.target
                 item = "DBInstance/"+r[:db_instance_id]
                 @ec2_main.serverCache.addDBInstance(r)
                 if item != ""
                    @ec2_main.server.load_rds_server(item)
                    @ec2_main.tabBook.setCurrent(1)
                 end
	    end 
	   end		
	end
	@launch_restore_button.connect(SEL_UPDATE) do |sender, sel, data|
             if loaded and @type ==  "rds"
                 sender.enabled = true
             else
                 sender.enabled = false
             end 
	end
	#
	# ec2 launch frame
	#
	@frame1 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
        @launch = {}
        FXLabel.new(@frame1, "Security Group" )
        @frame1s = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Security_Group'] = FXTextField.new(@frame1s, 25, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1s, "" )
 	FXLabel.new(@frame1s, "Chef Node" )
 	@launch['Chef_Node'] = FXTextField.new(@frame1s, 21, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Additional Security Groups" )
 	@launch['Additional_Security_Groups'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Tags" )
        @launch['Tags'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        @edit = @ec2_main.makeIcon("application_edit.png")
        @edit.create
        @launch['Tags_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
        @launch['Tags_Button'].icon = @edit
        @launch['Tags_Button'].tipText = "Edit Tags"
        @launch['Tags_Button'].connect(SEL_COMMAND) do
           dialog = EC2_TagsEditDialog.new(@ec2_main, "Launch", @resource_tags)
           dialog.execute
           if dialog.saved
	      @resource_tags = dialog.resource_tags
	      @launch['Tags'].text = @resource_tags.show
           end   
        end
 	FXLabel.new(@frame1, "Image Id" )
 	@launch['Image_Id'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@frame1z = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Image_Id_Button'] = FXButton.new(@frame1z, "", :opts => BUTTON_TOOLBAR)
 	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@launch['Image_Id_Button'].icon = @magnifier
	@launch['Image_Id_Button'].tipText = "Select Image"
	@launch['Image_Id_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_ImageDialog.new(@ec2_main)
	   @dialog.execute
	   img = @dialog.selected
	   if img != nil and img != ""
	      put('Image_Id',img)
	      image_info
	   end   
	end
	@launch['attributes_button'] = FXButton.new(@frame1z, " ",:opts => BUTTON_TOOLBAR)
	@view = @ec2_main.makeIcon("application_view_icons.png")
	@view.create
	@launch['attributes_button'].icon = @view
	@launch['attributes_button'].tipText = "  Image Attributes  "
	@launch['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
	    @curr_item = @launch['Image_Id'].text
            if @curr_item == nil or @curr_item == ""
               error_message("No Image Id","No Image Id specified to display attributes")
            else
               imagedialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
               imagedialog.execute
            end
	end
	@launch['market_button'] = FXButton.new(@frame1z, " ",:opts => BUTTON_TOOLBAR)
	@market_icon = @ec2_main.makeIcon("cloudmarket.png")
	@market_icon.create
	@launch['market_button'].icon = @market_icon
	@launch['market_button'].tipText = "  CloudMarket Info  "
	@launch['market_button'].connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.environment.browser("http://thecloudmarket.com/image/#{@launch['Image_Id'].text}")
	end	
 	FXLabel.new(@frame1, "Image Manifest" )
 	@launch['Image_Manifest'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Image Architecture" )
 	@frame1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Image_Architecture'] = FXTextField.new(@frame1a , 13, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1a, "" )
 	FXLabel.new(@frame1a, "Visibility" )
 	@launch['Image_Visibility'] = FXTextField.new(@frame1a, 12, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1a, "Root Device" )
 	@launch['Image_Root_Device_Type'] = FXTextField.new(@frame1a, 12, nil, 0, :opts => TEXTFIELD_READONLY)
 	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Image Block Device")
	@launch['Image_Block_Devices'] = FXTable.new(@frame1,:height => 40, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@launch['Image_Block_Devices'].connect(SEL_COMMAND) do |sender, sel, which|
	   @image_bm.set_curr_row(which.row)
	   @launch['Image_Block_Devices'].selectRow(@image_bm.curr_row)
	end 
        @launch['Image_Block_Devices_Button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
	@launch['Image_Block_Devices_Button'].icon = @edit
	@launch['Image_Block_Devices_Button'].tipText = "  Edit Image Block Device  "
	@launch['Image_Block_Devices_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	      if @image_bm.curr_row == nil
		 error_message("No Block Device selected","No Block Device selected to edit")
              else	
	         editdialog = EC2_BlockMappingEditDialog.new(@ec2_main,@image_bm.get,true)
                 editdialog.execute
                 if editdialog.saved 
                    bm = editdialog.block_mapping
                    @image_bm.update(bm)
                    @image_bm.load_table(@launch['Image_Block_Devices'])
                  end
              end   
        end		
        FXLabel.new(@frame1, "Spot Price" )
        @frame1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Spot_Price'] = FXTextField.new(@frame1b, 15, nil, 0, :opts => FRAME_SUNKEN)
 	@launch['Spot_Price_Button'] = FXButton.new(@frame1b, "", :opts => BUTTON_TOOLBAR)
 	@launch['Spot_Price_Button'].icon = @market_icon
	@launch['Spot_Price_Button'].tipText = " CloudMarket Spot Prices "
	@launch['Spot_Price_Button'].connect(SEL_COMMAND) do
	   @ec2_main.environment.browser("http://thecloudmarket.com/stats#/spot_prices")
	end
	FXLabel.new(@frame1b, "    Addressing (Eucalyptus)" )
	@launch['Addressing'] = FXTextField.new(@frame1b, 15, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1, "" )	
 	FXLabel.new(@frame1, "Minimum Server Count" )
 	@frame1c = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Minimum_Server_Count'] = FXTextField.new(@frame1c, 15, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1c, "" )
 	FXLabel.new(@frame1c, "         Max Server Count  " )
 	@launch['Maximum_Server_Count'] = FXTextField.new(@frame1c, 15, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Instance Type" )
 	@frame1d = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Instance_Type'] = FXTextField.new(@frame1d, 15, nil, 0, :opts => FRAME_SUNKEN)
        @launch['Instance_Type_Button'] = FXButton.new(@frame1d, "", :opts => BUTTON_TOOLBAR)
 	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@launch['Instance_Type_Button'].icon = @magnifier
	@launch['Instance_Type_Button'].tipText = "Select Instance Type"
	@launch['Instance_Type_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_InstanceDialog.new(@ec2_main)
	   @dialog.execute
	   type = @dialog.selected
	   if type != nil and type != ""
	      put('Instance_Type',type)
	   end   
	end
 	FXLabel.new(@frame1d, "    Availability Zone     ")
 	@launch['Availability_Zone'] = FXTextField.new(@frame1d, 15, nil, 0, :opts => FRAME_SUNKEN)
 	@launch['Availability_Zone_Button'] = FXButton.new(@frame1d, "", :opts => BUTTON_TOOLBAR)
	@launch['Availability_Zone_Button'].icon = @magnifier
	@launch['Availability_Zone_Button'].tipText = "Select Availability Zone"
	@launch['Availability_Zone_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   @dialog.execute
	   az = @dialog.selected
	   if az != nil and az != ""
	      put('Availability_Zone',az)
	   end   
	end
	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "Keypair" )
 	@frame1e = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
 	@launch['Keypair'] = FXTextField.new(@frame1e, 15, nil, 0, :opts => FRAME_SUNKEN)
 	@launch['Keypair_Button'] = FXButton.new(@frame1e, "", :opts => BUTTON_TOOLBAR)
	@launch['Keypair_Button'].icon = @magnifier
	@launch['Keypair_Button'].tipText = "Select Keypair"
	@launch['Keypair_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_KeypairDialog.new(@ec2_main)
	   @dialog.execute
	   keypair = @dialog.selected
	   if keypair != nil and keypair != ""
	      put('Keypair',keypair)
	   end   
	end
	FXLabel.new(@frame1e, "   Monitoring State      " )
	@launch['Monitoring_State'] = FXComboBox.new(@frame1e, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
	@launch['Monitoring_State'].numVisible = 2      
	@launch['Monitoring_State'].appendItem("disabled")	
	@launch['Monitoring_State'].appendItem("enabled")
	@launch['Monitoring_State'].setCurrentItem(0)
	FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "Disable Api Termination" )
        @frame1f = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
	@launch['Disable_Api_Termination'] = FXComboBox.new(@frame1f, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
	@launch['Disable_Api_Termination'].numVisible = 2      
	@launch['Disable_Api_Termination'].appendItem("true")	
	@launch['Disable_Api_Termination'].appendItem("false")
	@launch['Disable_Api_Termination'].setCurrentItem(1)	
        FXLabel.new(@frame1f, "  Instance Init Shutdown" )
	@launch['Instance_Initiated_Shutdown_Behavior'] = FXComboBox.new(@frame1f, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
	@launch['Instance_Initiated_Shutdown_Behavior'].numVisible = 2      
	@launch['Instance_Initiated_Shutdown_Behavior'].appendItem("stop")	
	@launch['Instance_Initiated_Shutdown_Behavior'].appendItem("terminate")
	@launch['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(0)
	FXLabel.new(@frame1, "" )
 	FXLabel.new(@frame1, "User Data Text (Startup Command)")
 	@launch['User_Data'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame1, "" )
 	#@launch['EBS_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	#@launch['EBS_Button'].icon = @magnifier
	#@launch['EBS_Button'].tipText = "Select EBS"
	#@launch['EBS_Button'].connect(SEL_COMMAND) do
	#   @dialog = EC2_EbsDialog.new(@ec2_main)
	#   @dialog.execute
	#   eb = @dialog.selected
	#   if eb != nil and eb != ""
	#      put('User_Data',eb)
	#      az = @dialog.availability_zone
	#      if az != nil and az != ""
	#        put('Availability_Zone',az)
	#      end   
	#   end   
	#end
	FXLabel.new(@frame1, "User Data File (Startup Script)")
 	@launch['User_Data_File'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@frame1y = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
	@launch['User_Data_File_Button'] = FXButton.new(@frame1y, "", :opts => BUTTON_TOOLBAR)
	@launch['User_Data_File_Button'].icon = @magnifier
	@launch['User_Data_File_Button'].tipText = "Browse..."
	@launch['User_Data_File_Button'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(@frame1, "Select User Data file")
	   dialog.patternList = [
	          "Pem Files (*.*)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @launch['User_Data_File'].text = dialog.filename
	   end
	end
        @launch['User_Data_File_Edit_Button'] = FXButton.new(@frame1y, "",:opts => BUTTON_TOOLBAR)
	@launch['User_Data_File_Edit_Button'].icon = @edit
	@launch['User_Data_File_Edit_Button'].tipText = "  Edit Script  "
	@launch['User_Data_File_Edit_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	   settings = @ec2_main.settings
	   editor = settings.get_system('EXTERNAL_EDITOR')
	   fn = @launch['User_Data_File'].text
	   puts "#{editor} #{fn}"
	   system editor+" "+fn
	end 
	FXLabel.new(@frame1, "Override EC2 SSH User" )
	@launch['EC2_SSH_User'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(@frame1, "" )	
	FXLabel.new(@frame1, "Override EC2 SSH Private Key" )
	@launch['EC2_SSH_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@launch['EC2_SSH_Private_Key_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	@launch['EC2_SSH_Private_Key_Button'].icon = @magnifier
	@launch['EC2_SSH_Private_Key_Button'].tipText = "Browse..."
	@launch['EC2_SSH_Private_Key_Button'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(@frame1, "Select pem file")
	   dialog.patternList = [
	          "Pem Files (*.pem)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @launch['EC2_SSH_Private_Key'].text = dialog.filename
	   end
	end
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil	
	   FXLabel.new(@frame1, "Override Putty Private Key" )
	   @launch['Putty_Private_Key'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @launch['Putty_Private_Key_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
	   @launch['Putty_Private_Key_Button'].icon = @magnifier
	   @launch['Putty_Private_Key_Button'].tipText = "Browse..."
	   @launch['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame1, "Select ppk file")
	      dialog.patternList = [
	          "Pem Files (*.ppk)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @launch['Putty_Private_Key'].text = dialog.filename
	      end
	   end
        end	   
	FXLabel.new(@frame1, "Win Admin Password" )
	@launch['Win_Admin_Password'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "Additional Info" )
	@launch['Additional_Info'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Additional Block Devices")
	@launch['Block_Devices'] = FXTable.new(@frame1,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@launch['Block_Devices'].connect(SEL_COMMAND) do |sender, sel, which|
           @block_mapping.set_curr_row(which.row)
	   @launch['Block_Devices'].selectRow(@block_mapping.curr_row)
	end
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Notes")
	@text_area = FXText.new(@frame1, :height => 100, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)
	#
	# rds launch frame
	#
	@frame2 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
	@frame2.hide()
        @rds_launch = {}
 	FXLabel.new(@frame2, "DBSecurity Group" )
 	@rds_launch['DBSecurity_Group'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Additional DBSecurity Groups" )
 	@rds_launch['Additional_DBSecurity_Groups'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBInstance Id" )
 	@rds_launch['DBInstanceId'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBName" )
 	@rds_launch['DBName'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
        FXLabel.new(@frame2, "DBInstance Class" )
 	@rds_launch['DBInstanceClass'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_launch['DBInstanceClass_Button'] = FXButton.new(@frame2, "", :opts => BUTTON_TOOLBAR)
        @magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@rds_launch['DBInstanceClass_Button'].icon = @magnifier
	@rds_launch['DBInstanceClass_Button'].tipText = "Select DBInstance Class"
	@rds_launch['DBInstanceClass_Button'].connect(SEL_COMMAND) do
	   @dialog = RDS_InstanceDialog.new(@ec2_main)
	   @dialog.execute
	   type = @dialog.selected
	   if type != nil and type != ""
	      rds_put('DBInstanceClass',type)
	   end   
	end
 	FXLabel.new(@frame2, "Allocated Storage" )
 	@rds_launch['AllocatedStorage'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
        FXLabel.new(@frame2, "Availability Zone")
 	@rds_launch['AvailabilityZone'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_launch['AvailabilityZone_Button'] = FXButton.new(@frame2, "", :opts => BUTTON_TOOLBAR)
	@rds_launch['AvailabilityZone_Button'].icon = @magnifier
	@rds_launch['AvailabilityZone_Button'].tipText = "Select Availability Zone"
	@rds_launch['AvailabilityZone_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   @dialog.execute
	   az = @dialog.selected
	   if az != nil and az != ""
	      rds_put('AvailabilityZone',az)
	   end   
	end 
        FXLabel.new(@frame2, "Multi AZ" )
    	@rds_launch['MultiAZ'] = FXComboBox.new(@frame2, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    	@rds_launch['MultiAZ'].numVisible = 2      
    	@rds_launch['MultiAZ'].appendItem("true")	
    	@rds_launch['MultiAZ'].appendItem("false")
    	@rds_launch['MultiAZ'].setCurrentItem(1)
    	@rds_launch['MultiAZ'].connect(SEL_COMMAND) do
    	end    
    	FXLabel.new(@frame2, "" )
	
 	FXLabel.new(@frame2, "Engine" )
 	@rds_launch['Engine'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_launch['Engine_Button'] = FXButton.new(@frame2, "", :opts => BUTTON_TOOLBAR)
	@rds_launch['Engine_Button'].icon = @magnifier
	@rds_launch['Engine_Button'].tipText = "  Select Engine and Engine Version  "
	@rds_launch['Engine_Button'].connect(SEL_COMMAND) do
	   @dialog = RDS_DBEngineVersionDialog.new(@ec2_main)
	   @dialog.execute
	   if @dialog.selected
	      rds_put('Engine',@dialog.engine)
	      rds_put('EngineVersion',@dialog.engine_version)
	   end   
	end 
 	FXLabel.new(@frame2, "Engine Version" )
 	@rds_launch['EngineVersion'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Master Username" )
 	@rds_launch['MasterUsername'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Master User Password" )
 	@rds_launch['MasterUserPassword'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
        FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "Preferred Maintenance Window" )
 	@rds_launch['PreferredMaintenanceWindow'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBParameter Group Name")
 	@rds_launch['DBParameterGroupName'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_launch['DBParameterGroupName_Button'] = FXButton.new(@frame2, "", :opts => BUTTON_TOOLBAR)
	@rds_launch['DBParameterGroupName_Button'].icon = @magnifier
	@rds_launch['DBParameterGroupName_Button'].tipText = "Select DB Parameter Group"
	@rds_launch['DBParameterGroupName_Button'].connect(SEL_COMMAND) do
	   @dialog = RDS_ParmGrpDialog.new(@ec2_main)
	   @dialog.execute
	   it = @dialog.selected
	   if it != nil and it != ""
	      rds_put('DBParameterGroupName',it)
	   end   
	end 	
	FXLabel.new(@frame2, "Backup Retention Period")
 	@rds_launch['BackupRetentionPeriod'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(@frame2, "" )
	FXLabel.new(@frame2, "Preferred Backup Window" )
	@rds_launch['PreferredBackupWindow'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(@frame2, "" )
 	FXLabel.new(@frame2, "DBSnapshot")
 	@rds_launch['DBSnapshot'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_launch['DBSnapshot_Button'] = FXButton.new(@frame2, "", :opts => BUTTON_TOOLBAR)
	@rds_launch['DBSnapshot_Button'].icon = @magnifier
	@rds_launch['DBSnapshot_Button'].tipText = "Select DB Snapshot"
	@rds_launch['DBSnapshot_Button'].connect(SEL_COMMAND) do
	   if @rds_launch['DBInstanceId'].text != nil and @rds_launch['DBInstanceId'].text != ""
	      @dialog = RDS_SnapDialog.new(@ec2_main,@rds_launch['DBInstanceId'].text)
	      @dialog.execute
	      it = @dialog.selected
	      if it != nil and it != ""
	         rds_put('DBSnapshot',it)
	      end
	   else
	      error_message("Error","DBInstanceId for DBSnapshot not specified")
	   end
	end	
	FXLabel.new(@frame2, "Port" )
	@rds_launch['Port'] = FXTextField.new(@frame2, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(@frame2, "" )
    	FXLabel.new(@frame2, "Auto Minor Version Upgrade" )
    	@rds_launch['AutoMinorVersionUpgrade'] = FXComboBox.new(@frame2, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    	@rds_launch['AutoMinorVersionUpgrade'].numVisible = 2      
    	@rds_launch['AutoMinorVersionUpgrade'].appendItem("true")	
    	@rds_launch['AutoMinorVersionUpgrade'].appendItem("false")
    	@rds_launch['AutoMinorVersionUpgrade'].setCurrentItem(0)
    	@rds_launch['AutoMinorVersionUpgrade'].connect(SEL_COMMAND) do
    	end    
    	FXLabel.new(@frame2, "" )

      	FXLabel.new(@frame2, "Read Replicas" )
	@rds_launch['Read_Replicas'] = FXTable.new(@frame2,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@rds_launch['Read_Replicas'].connect(SEL_COMMAND) do |sender, sel, which|
           @read_replica_curr_row = which.row 
	   @rds_launch['Read_Replicas'].selectRow(@read_replica_curr_row)
	end
   	page2a = FXHorizontalFrame.new(@frame2,LAYOUT_FILL_X, :padding => 0)
	@rds_launch['Read_Replicas_Launch_Button'] = FXButton.new(page2a, " ",:opts => BUTTON_TOOLBAR)
	@rds_launch['Read_Replicas_Launch_Button'].icon = @rocket
	@rds_launch['Read_Replicas_Launch_Button'].tipText = "  Launch Read Replica  "
	@rds_launch['Read_Replicas_Launch_Button'].connect(SEL_COMMAND) do |sender, sel, data|
		if @read_replica_curr_row == nil
		   error_message("No Read Replica selected","No Read Replica selected to launch")
                else
                   launch_rds_read_replica(@read_replica[@read_replica_curr_row])
	        end  
	end
	@rds_launch['Read_Replicas_Launch_Button'] .connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end   	
      	@rds_launch['Read_Replicas_Create_Button']= FXButton.new(page2a, " ",:opts => BUTTON_TOOLBAR)
	@rds_launch['Read_Replicas_Create_Button'].icon = @create
	@rds_launch['Read_Replicas_Create_Button'].tipText = "  Add Read Replica  "
	@rds_launch['Read_Replicas_Create_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	      rr = {} 
              rr[:source_db_instance_id] = @rds_launch['DBInstanceId'].text 
	      editdialog = RDS_ReadReplicaEditDialog.new(@ec2_main,rr)
              editdialog.execute
              if editdialog.returned 
                rr = editdialog.read_replica
                @read_replica.push(rr)
                load_rds_read_replica_table
              end
        end
     	@rds_launch['Read_Replicas_Create_Button'] .connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
      	@rds_launch['Read_Replicas_Edit_Button'] = FXButton.new(page2a, " ",:opts => BUTTON_TOOLBAR)
	@rds_launch['Read_Replicas_Edit_Button'].icon = @view
	@rds_launch['Read_Replicas_Edit_Button'].tipText = "  View Read Replica  "
	@rds_launch['Read_Replicas_Edit_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	      if @read_replica_curr_row  == nil
		 error_message("No Read Replica selected","No Read Replica selected to view")
              else	
	         editdialog = RDS_ReadReplicaEditDialog.new(@ec2_main,@read_replica[@read_replica_curr_row] )
                 editdialog.execute
              end   
     	end
     	@rds_launch['Read_Replicas_Edit_Button'] .connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@rds_launch['Read_Replicas_Delete_Button'] = FXButton.new(page2a, " ",:opts => BUTTON_TOOLBAR)
	@rds_launch['Read_Replicas_Delete_Button'].icon = @delete
	@rds_launch['Read_Replicas_Delete_Button'].tipText = "  Delete Read Replica  "
	@rds_launch['Read_Replicas_Delete_Button'].connect(SEL_COMMAND) do |sender, sel, data|
		if @read_replica_curr_row == nil
		   error_message("No Read Replica selected","No Read Replica selected to delete")
                else
                   rr = @read_replica[@read_replica_curr_row] 
                   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm Delete of Read Replica #{rr[:db_instance_id]}")
                   if answer == MBOX_CLICKED_YES
                      @read_replica.delete_at(@read_replica_curr_row)
                      load_rds_read_replica_table
                   end   
	        end  
	end
	@rds_launch['Read_Replicas_Delete_Button'] .connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end	

	FXLabel.new(@frame2, "Notes")
	@rds_text_area = FXText.new(@frame2, :height => 100, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)
	
	#
	# auto scaling launch configuration frame
	#
	@frame3 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
        @frame3.hide()
        @as_launch = {}
 	FXLabel.new(@frame3, "Launch Config Name" )
 	@as_launch['Launch_Configuration_Name'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "Created Time" )
	@as_launch['Created_Time'] = FXTextField.new(@frame3, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Security Groups" )
 	@as_launch['Security_Groups'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "Image Id" )
 	@as_launch['Image_Id'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@frame3z = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
 	@as_launch['Image_Id_Button'] = FXButton.new(@frame3z, "", :opts => BUTTON_TOOLBAR)
 	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@as_launch['Image_Id_Button'].icon = @magnifier
	@as_launch['Image_Id_Button'].tipText = "Select Image"
	@as_launch['Image_Id_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_ImageDialog.new(@ec2_main)
	   @dialog.execute
	   img = @dialog.selected
	   if img != nil and img != ""
	      as_put('Image_Id',img)
	   end   
	end
	@as_launch['attributes_button'] = FXButton.new(@frame3z, " ",:opts => BUTTON_TOOLBAR)
	@view = @ec2_main.makeIcon("application_view_icons.png")
	@view.create
	@as_launch['attributes_button'].icon = @view
	@as_launch['attributes_button'].tipText = "  Image Attributes  "
	@as_launch['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
	    @curr_item = @as_launch['Image_Id'].text
            if @curr_item == nil or @curr_item == ""
               error_message("No Image Id","No Image Id specified to display attributes")
            else
               imagedialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
               imagedialog.execute
            end
	end
	@as_launch['market_button'] = FXButton.new(@frame3z, " ",:opts => BUTTON_TOOLBAR)
	@market_icon = @ec2_main.makeIcon("cloudmarket.png")
	@market_icon.create
	@as_launch['market_button'].icon = @market_icon
	@as_launch['market_button'].tipText = "  CloudMarket Info  "
	@as_launch['market_button'].connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.environment.browser("http://thecloudmarket.com/image/#{@as_launch['Image_Id'].text}")
	end	
 	FXLabel.new(@frame3, "Kernel Id" )
 	@as_launch['Kernel_Id'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "RamdiskId" )
 	@as_launch['Ramdisk_Id'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "UserData" )
 	@as_launch['UserData'] = FXTextField.new(@frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame3, "" )
   	FXLabel.new(@frame3, "Instance Type" )
   	@frame3d = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
 	@as_launch['Instance_Type'] = FXTextField.new(@frame3d, 15, nil, 0, :opts => FRAME_SUNKEN)
        @as_launch['Instance_Type_Button'] = FXButton.new(@frame3d, "", :opts => BUTTON_TOOLBAR)
 	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@as_launch['Instance_Type_Button'].icon = @magnifier
	@as_launch['Instance_Type_Button'].tipText = "Select Instance Type"
	@as_launch['Instance_Type_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_InstanceDialog.new(@ec2_main)
	   @dialog.execute
	   type = @dialog.selected
	   if type != nil and type != ""
	      @as_launch['Instance_Type'].text = type
	   end   
	end
	FXLabel.new(@frame3, "" )
 	FXLabel.new(@frame3, "KeyName" )
	@frame3e = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0) 	
 	@as_launch['KeyName'] = FXTextField.new(@frame3e, 15, nil, 0, :opts => FRAME_SUNKEN)
 	@as_launch['KeyName_Button'] = FXButton.new(@frame3e, "", :opts => BUTTON_TOOLBAR)
	@as_launch['KeyName_Button'].icon = @magnifier
	@as_launch['KeyName_Button'].tipText = "Select Keypair"
	@as_launch['KeyName_Button'].connect(SEL_COMMAND) do
	   @dialog = EC2_KeypairDialog.new(@ec2_main)
	   @dialog.execute
	   keypair = @dialog.selected
	   if keypair != nil and keypair != ""
	      @as_launch['KeyName'].text=keypair
	   end   
	end
	FXLabel.new(@frame3, "" )
	FXLabel.new(@frame3, "Block Device Mappings")
	@as_launch['Block_Device_Mappings'] = FXTable.new(@frame3,:height => 40, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@as_launch['Block_Device_Mappings'].connect(SEL_COMMAND) do |sender, sel, which|
	   @as_bm.curr_row = which.row
	   @as_launch['Block_Devices_Mappings'].selectRow(@as_bm.curr_row)
	end 
   	page3a = FXHorizontalFrame.new(@frame3,LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(page3a, " ",:opts => LAYOUT_LEFT )
        @as_launch['Block_Device_Mappings_Create_Button'] = FXButton.new(page3a, " ",:opts => BUTTON_TOOLBAR)
	@as_launch['Block_Device_Mappings_Create_Button'].icon = @create
	@as_launch['Block_Device_Mappings_Create_Button'].tipText = "  Add Block Device  "
	@as_launch['Block_Device_Mappings_Create_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	      editdialog = AS_BlockMappingEditDialog.new(@ec2_main,nil)
              editdialog.execute
              if editdialog.saved 
                bm = editdialog.block_mapping
                @as_bm.push(bm)
                @as_bm.load_table(@as_launch['Block_Device_Mappings'])
              end
        end	
        @as_launch['Block_Device_Mappings_Create_Button'].connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
        @as_launch['Block_Device_Mappings_Edit_Button'] = FXButton.new(page3a, " ",:opts => BUTTON_TOOLBAR)
	@as_launch['Block_Device_Mappings_Edit_Button'].icon = @edit
	@as_launch['Block_Device_Mappings_Edit_Button'].tipText = "  Edit Block Device  "
	@as_launch['Block_Device_Mappings_Edit_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	      if @as_bm.curr_row == nil
		 error_message("No Block Device selected","No Block Device selected to edit")
              else	
	         editdialog = AS_BlockMappingEditDialog.new(@ec2_main,@as_bm.get)
                 editdialog.execute
                 if editdialog.saved 
                    bm = editdialog.block_mapping
                    @as_bm.update(bm)
                    @as_bm.load_table(@as_launch['Block_Device_Mappings'])
                 end
              end   
        end	
	@as_launch['Block_Device_Mappings_Delete_Button'] = FXButton.new(page3a, " ",:opts => BUTTON_TOOLBAR)
	@as_launch['Block_Device_Mappings_Delete_Button'].icon = @delete
	@as_launch['Block_Device_Mappings_Delete_Button'].tipText = "  Delete Block Device  "
	@as_launch['Block_Device_Mappings_Delete_Button'].connect(SEL_COMMAND) do |sender, sel, data|
		if @as_bm.curr_row == nil
		   error_message("No Block Device selected","No Block Device selected to delete")
                else
                   m = @as_bm.get
                   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Block Device #{m[:device_name]}")
                   if answer == MBOX_CLICKED_YES
                      @as_bm.delete
                      @as_bm.load_table(@as_launch['Block_Device_Mappings'])                   
                   end   
	        end  
	end	
	@as_launch['Block_Device_Mappings_Delete_Button'].connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end
	#
	# openstack launch frame
	#
	@frame4 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
	@frame4.hide()
        @ops_launch = {}
        FXLabel.new(@frame4, "Security Group" )
        @frame4s = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
 	@ops_launch['Security_Group'] = FXTextField.new(@frame4s, 25, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame4s, "" )
 	FXLabel.new(@frame4s, "Chef Node" )
 	@ops_launch['Chef_Node'] = FXTextField.new(@frame4s, 21, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame4, "" )
 	FXLabel.new(@frame4, "Name" )
 	@ops_launch['Name'] = FXTextField.new(@frame4, 25, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame4, "" ) 	
 	FXLabel.new(@frame4, "Image Id" )
 	@frame4z = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
 	@ops_launch['Image_Id'] = FXTextField.new(@frame4z, 20, nil, 0, :opts => FRAME_SUNKEN)
 	@ops_launch['Image_Id_Button'] = FXButton.new(@frame4z, "", :opts => BUTTON_TOOLBAR)
	@ops_launch['Image_Id_Button'].icon = @magnifier
	@ops_launch['Image_Id_Button'].tipText = "Select Image"
	@ops_launch['Image_Id_Button'].connect(SEL_COMMAND) do
	   @dialog = OPS_ImageDialog.new(@ec2_main)
	   @dialog.execute
	   img = @dialog.selected
	   img_name = @dialog.img_name
	   if img != nil and img != ""
	      ops_put('Image_Id',img)
	      ops_put('Image_Name',img_name)
	   end   
	end
	@ops_launch['attributes_button'] = FXButton.new(@frame4z, " ",:opts => BUTTON_TOOLBAR)
	@ops_launch['attributes_button'].icon = @view
	@ops_launch['attributes_button'].tipText = "  Image Attributes  "
	@ops_launch['attributes_button'].connect(SEL_COMMAND) do |sender, sel, data|
	    #@curr_item = @launch['Image_Id'].text
            #if @curr_item == nil or @curr_item == ""
            #   error_message("No Image Id","No Image Id specified to display attributes")
            #else
            #   imagedialog = OPS_ImageAttributeDialog.new(@ec2_main,@curr_item)
            #   imagedialog.execute
            #end
	end
	FXLabel.new(@frame4, "" )
 	FXLabel.new(@frame4, "Image Name" )
 	@ops_launch['Image_Name'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN|TEXT_READONLY)
 	FXLabel.new(@frame4, "" )
 	FXLabel.new(@frame4, "Flavor" )
 	@frame4d = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
 	@ops_launch['Flavor'] = FXTextField.new(@frame4d, 15, nil, 0, :opts => FRAME_SUNKEN)
        @ops_launch['Flavor_Button'] = FXButton.new(@frame4d, "", :opts => BUTTON_TOOLBAR)
	@ops_launch['Flavor_Button'].icon = @magnifier
	@ops_launch['Flavor_Button'].tipText = "Select Flavour"
	@ops_launch['Flavor_Button'].connect(SEL_COMMAND) do
	   @dialog = OPS_FlavorDialog.new(@ec2_main)
	   @dialog.execute
	   type = @dialog.selected
	   if type != nil and type != ""
	      ops_put('Flavor',type)
	   end   
	end
	FXLabel.new(@frame4, "" ) 
 	FXLabel.new(@frame4, "Keyname" )
 	@ops_launch['Keyname'] = FXTextField.new(@frame4, 15, nil, 0, :opts => FRAME_SUNKEN) 	
 	#@ops_launch['Keyname_Button'] = FXButton.new(@frame4 "", :opts => BUTTON_TOOLBAR)
	#@ops_launch['Keyname_Button'].icon = @magnifier
	#@ops_launch['Keyname_Button'].tipText = "Select Keypair"
	#@ops_launch['Keyname_Button'].connect(SEL_COMMAND) do
	   #@dialog = OPS_KeypairDialog.new(@ec2_main)
	   #@dialog.execute
	   #keypair = @dialog.selected
	   #if keypair != nil and keypair != ""
	   #   put('Keypair',keypair)
	   #end   
	#end
	FXLabel.new(@frame4, "" )
 	FXLabel.new(@frame4, "User Data Text (Startup Command)")
 	@ops_launch['User_Data'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(@frame4, "" )
	FXLabel.new(@frame4, "User Data File (Startup Script)")
 	@ops_launch['User_Data_File'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
 	@frame4y = FXHorizontalFrame.new(@frame4,LAYOUT_FILL_X, :padding => 0)
	@ops_launch['User_Data_File_Button'] = FXButton.new(@frame4y, "", :opts => BUTTON_TOOLBAR)
	@ops_launch['User_Data_File_Button'].icon = @magnifier
	@ops_launch['User_Data_File_Button'].tipText = "Browse..."
	@ops_launch['User_Data_File_Button'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(@frame4, "Select User Data file")
	   dialog.patternList = [
	          "Pem Files (*.*)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @ops_launch['User_Data_File'].text = dialog.filename
	   end
	end
        @ops_launch['User_Data_File_Edit_Button'] = FXButton.new(@frame1y, "",:opts => BUTTON_TOOLBAR)
	@ops_launch['User_Data_File_Edit_Button'].icon = @edit
	@ops_launch['User_Data_File_Edit_Button'].tipText = "  Edit Script  "
	@ops_launch['User_Data_File_Edit_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	   settings = @ec2_main.settings
	   editor = settings.get_system('EXTERNAL_EDITOR')
	   fn = @ops_launch['User_Data_File'].text
	   puts "#{editor} #{fn}"
	   system editor+" "+fn
	end
	FXLabel.new(@frame4, "Admin Password" )
	@ops_launch['Admin_Password'] = FXTextField.new(@frame4, 25, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(@frame4, "" )	
	FXLabel.new(@frame4, "Override SSH User" )
	@ops_launch['SSH_User'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(@frame4, "" )	
	FXLabel.new(@frame4, "Override SSH Private Key" )
	@ops_launch['SSH_Private_Key'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@ops_launch['SSH_Private_Key_Button'] = FXButton.new(@frame4, "", :opts => BUTTON_TOOLBAR)
	@ops_launch['SSH_Private_Key_Button'].icon = @magnifier
	@ops_launch['SSH_Private_Key_Button'].tipText = "Browse..."
	@ops_launch['SSH_Private_Key_Button'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(@frame1, "Select pem file")
	   dialog.patternList = [
	          "Pem Files (*.pem)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @ops_launch['SSH_Private_Key'].text = dialog.filename
	   end
	end
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil	
	   FXLabel.new(@frame4, "Override Putty Private Key" )
	   @ops_launch['Putty_Private_Key'] = FXTextField.new(@frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	   @ops_launch['Putty_Private_Key_Button'] = FXButton.new(@frame4, "", :opts => BUTTON_TOOLBAR)
	   @ops_launch['Putty_Private_Key_Button'].icon = @magnifier
	   @ops_launch['Putty_Private_Key_Button'].tipText = "Browse..."
	   @ops_launch['Putty_Private_Key_Button'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(@frame1, "Select ppk file")
	      dialog.patternList = [
	          "Pem Files (*.ppk)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @ops_launch['Putty_Private_Key'].text = dialog.filename
	      end
	   end
        end	 	
	FXLabel.new(@frame4, "Notes")
	@ops_text_area = FXText.new(@frame4, :height => 100, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)	
  end 	
  
 	
 def enable_if_env_set(sender)
       @env = @ec2_main.environment.env
       if @env != nil and @env.length>0
       	sender.enabled = true
       else
         sender.enabled = false
       end
 end
 
  def loaded
      return @launch_loaded
  end   
 
 def enable_if_launch_loaded(sender)
       if loaded 
           sender.enabled = true
       else
           sender.enabled = false
       end 
 end
 
 def launchPanel(item)
       load(item.text)
 end 
 
 
end
