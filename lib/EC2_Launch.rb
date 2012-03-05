require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_ImageDialog'
require 'dialog/EC2_InstanceDialog'
require 'dialog/EC2_KeypairDialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/RDS_InstanceDialog'
require 'dialog/RDS_ParmGrpDialog'
require 'dialog/EC2_EbsDialog'
require 'dialog/RDS_SnapDialog'
require 'dialog/RDS_RestoreTimeDialog'
require 'dialog/RDS_ReadReplicaEditDialog'
require 'dialog/RDS_DBEngineVersionDialog' 
require 'dialog/EC2_BlockMappingEditDialog'
require 'dialog/AS_BlockMappingEditDialog'
require 'dialog/EC2_ImageAttributeDialog'
require 'common/EC2_Block_Mapping'
require 'common/EC2_ResourceTags'


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
	    elsif @type == "rds"
               launch_rds_instance
	    end		
	end
	@launch_button.connect(SEL_UPDATE) do |sender, sel, data|
         sender.enabled = false
	   if @type == "ec2"
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
   	page1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
        @create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@create = @ec2_main.makeIcon("new.png")
	@create.create
	@create_button.icon = @create
	@create_button.tipText = "  Add Block Device  "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	      editdialog = EC2_BlockMappingEditDialog.new(@ec2_main,nil)
              editdialog.execute
              if editdialog.saved 
                bm = editdialog.block_mapping
                @block_mapping.push(bm)
                @block_mapping.load_table(@launch['Block_Devices'])
              end
        end
        @create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
        @edit_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
	@edit_button.icon = @edit
	@edit_button.tipText = "  Edit Block Device  "
	@edit_button.connect(SEL_COMMAND) do |sender, sel, data|
	      if @block_mapping.curr_row == nil
		 error_message("No Block Device selected","No Block Device selected to edit")
              else	
	         editdialog = EC2_BlockMappingEditDialog.new(@ec2_main,@block_mapping.get)
                 editdialog.execute
                 if editdialog.saved 
                    bm = editdialog.block_mapping
                    @block_mapping.update(bm)
                    @block_mapping.load_table(@launch['Block_Devices'])
                 end
              end   
        end	
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@delete_button.icon = @delete
	@delete_button.tipText = "  Delete Block Device  "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
		if @block_mapping.curr_row == nil
		   error_message("No Block Device selected","No Block Device selected to delete")
                else
                   m = @block_mapping.get
                   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Block Device #{m[:device_name]}")
                   if answer == MBOX_CLICKED_YES
                      @block_mapping.delete
                      @block_mapping.load_table(@launch['Block_Devices'])                   
                   end   
	        end  
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end	
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
 
 #
 #  ec2 methods
 #
 
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
       if platform == "Eucalyptus"
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
       if platform != "Eucalyptus"
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
                puts "m #{m}"
	        sa = (m[:ebs_snapshot_id]).split"/"
		  if sa.size>1
                   m[:ebs_snapshot_id]=sa[1]
	        end
              bm[i]=m
              i = i+1
           end   
           launch_parm[:block_device_mappings] = bm
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
             gi = r[:groups][0][:group_name]
    	     item_server = gi+"/"+r[:aws_instance_id]
          end
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
     if platform == "Eucalyptus"
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
      clear_panel      
      @type = "ec2"
      @profile_type = "secgrp"
      @profile_folder = "launch"
      @frame1.show()
      @frame2.hide()
      @frame3.hide()
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
               if r[:aws_architecture] == "x86_64"
	          put('Instance_Type',"m1.large")
	       else
	          put('Instance_Type',"m1.small")
	       end   
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

#
#  rds methods
#

 def launch_rds_Panel(item)
       load_rds(item.text)
 end 
 
 def launch_rds_instance
    puts "launch.launch_rds_instance"
    server = @rds_launch['DBInstanceId'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of DB Instance "+server)
    if answer == MBOX_CLICKED_YES
     rds = @ec2_main.environment.rds_connection
     if rds != nil
       launch_parm = Hash.new
       dbname = @rds_launch['DBName'].text
       g = Array.new
       if @rds_launch['Additional_DBSecurity_Groups'].text == nil or @rds_launch['Additional_DBSecurity_Groups'].text == ""
          g[0] = @rds_launch['DBSecurity_Group'].text
       else
          g[0] = @rds_launch['DBSecurity_Group'].text
          a = @rds_launch['Additional_DBSecurity_Groups'].text
          i = 1
          a.each(",") do |s|
           g[i] = s[0..s.length-1]
           i = i+1
          end 
       end
       launch_parm[:db_security_groups] = g       
       launch_parm[:aws_id] = @rds_launch['DBInstanceId'].text
       launch_parm[:db_name] = @rds_launch['DBName'].text
       launch_parm[:instance_class] = @rds_launch['DBInstanceClass'].text
       if @rds_launch['AllocatedStorage'].text != nil and @rds_launch['AllocatedStorage'].text != ""
          launch_parm[:allocated_storage] = (@rds_launch['AllocatedStorage'].text).to_i
       end   
       launch_parm[:availability_zone] = @rds_launch['AvailabilityZone'].text
       if @rds_launch['MultiAZ'].itemCurrent?(0)
          launch_parm[:multi_az] = "true"
        end
       launch_parm[:engine] = @rds_launch['Engine'].text
       launch_parm[:engine_version] = @rds_launch['EngineVersion'].text
       launch_parm[:master_username] = @rds_launch['MasterUsername'].text
       launch_parm[:master_user_password] = @rds_launch['MasterUserPassword'].text
       launch_parm[:preferred_maintenance_window] = @rds_launch['PreferredMaintenanceWindow'].text
       launch_parm[:db_parameter_group] = @rds_launch['DBParameterGroupName'].text
       launch_parm[:backup_retention_period] = @rds_launch['BackupRetentionPeriod'].text
       launch_parm[:preferred_backup_window] = @rds_launch['PreferredBackupWindow'].text
       launch_parm[:endpoint_port] = @rds_launch['Port'].text
       if @rds_launch['AutoMinorVersionUpgrade'].itemCurrent?(1)
          launch_parm[:auto_minor_version_upgrade] = "false"
        end
 
       rds_save
       puts "launch server "+server
       begin
         item = ""
         r = rds.create_db_instance(launch_parm[:aws_id], launch_parm[:master_username], launch_parm[:master_user_password], launch_parm)
         item = "DBInstance/"+r[:aws_id]
         @ec2_main.serverCache.addDBInstance(r)
         if item != ""
            @ec2_main.server.load_rds_server(item)
            @ec2_main.tabBook.setCurrent(1)
         end
       rescue
         error_message("Launch Failed",$!.to_s)
       end  
     end
    end 
 end     
 
  def launch_rds_read_replica(rr)
    puts "launch.launch_rds_read_replica"
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Read Replica DB Instance #{rr[:db_instance_id]}")
    if answer == MBOX_CLICKED_YES
       rds = @ec2_main.environment.rds_connection
       if rds != nil
          begin
             item = ""
             r = rds.create_db_instance_read_replica(rr[:db_instance_id], rr[:source_db_instance_id], rr)
             item = "DBInstance/"+r[:aws_id]
             @ec2_main.serverCache.addDBInstance(r)
             if item != ""
                @ec2_main.server.load_rds_server(item)
                @ec2_main.tabBook.setCurrent(1)
             end
          rescue
             error_message("Launch Failed",$!.to_s)
          end
       end
    end  
  end

 def restore_rds_instance
     puts "launch.restore_rds_instance"
     server = @rds_launch['DBInstanceId'].text
     snap = @rds_launch['DBSnapshot'].text
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
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Restore","Confirm Restore of DB Instance "+server+" from DBsnapshot "+snap)
     if answer == MBOX_CLICKED_YES
        rds = @ec2_main.environment.rds_connection
        if rds != nil
           begin 
              r = rds.restore_db_instance_from_db_snapshot(snap, server, params)
              @created = true
              item = "DBInstance/"+r[:aws_id]
              @ec2_main.serverCache.addDBInstance(r)
              if item != ""
                 @ec2_main.server.load_rds_server(item)
                 @ec2_main.tabBook.setCurrent(1)
              end
           rescue
              error_message("Restore DBInstance Failed",$!.to_s)
           end  
        end
     end 
 end     
 
 def load_rds(sec_grp)
      puts "Launch.load"
      @type = "rds"
      @frame1.hide()
      @frame2.show()
      @frame3.hide()
      @profile_type = "secgrp"
      @profile_folder = "dblaunch"
      clear_rds_panel
      @profile = sec_grp
      @rds_launch['DBSecurity_Group'].text = @profile
      @rds_launch['DBSecurity_Group'].enabled = false
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
        load_rds_panel('DBSecurity_Group')
        load_rds_panel('Additional_DBSecurity_Groups')
        load_rds_panel('DBInstanceId')
        load_rds_panel('DBName')
        load_rds_panel('DBInstanceClass')
        load_rds_panel('AllocatedStorage')
        load_rds_panel('AvailabilityZone')
	load_rds_panel_true_false('MultiAZ')
        load_rds_panel('Engine')
        load_rds_panel('EngineVersion')
        #load_ApplyImmediately
        load_rds_panel('MasterUsername')
        load_rds_panel('MasterUserPassword')
        load_rds_panel('PreferredMaintenanceWindow')
        load_rds_panel('DBParameterGroupName')
        load_rds_panel('BackupRetentionPeriod')
        load_rds_panel('PreferredBackupWindow')
        load_rds_panel('DBSnapshot')
        load_rds_panel('Port')
        load_rds_panel_true_false('AutoMinorVersionUpgrade')
        load_rds_read_replica
        @launch_loaded = true
      else
        # default to empty values
        @rds_launch['DBInstanceId'].text = sec_grp
        @rds_launch['DBInstanceClass'].text = "db.m1.small"
        @rds_launch['AllocatedStorage'].text = "5"
        @rds_launch['Engine'].text = "mysql"
        @rds_launch['EngineVersion'].text = "5.1.45"
        @rds_launch['PreferredMaintenanceWindow'].text = "Sun:05:00-Sun:09:00"
        @rds_launch['BackupRetentionPeriod'].text = "0"
        @rds_launch['PreferredBackupWindow'].text = "01:00-03:00"
        @rds_launch['Port'].text = "3306"
        @rds_launch['MultiAZ'].setCurrentItem(1)
        @rds_launch['AutoMinorVersionUpgrade'].setCurrentItem(0)
        @launch_loaded = true
      end
      load_notes      
      @ec2_main.app.forceRefresh
 end 
   
    
   def load_rds_panel_true_false(field)
     if @properties[field] == 'true'
        @rds_launch[field].setCurrentItem(0)
     else
        @rds_launch[field].setCurrentItem(1)
     end   
   end
   
   def load_rds_panel(key)
    if @properties[key] != nil
      @rds_launch[key].text = @properties[key]
    end
   end 
   
   def clear_rds_panel
     puts "Launch.clear_rds_panel" 
     @profile = ""
     @resource_tags = nil 
     rds_clear('DBSecurity_Group')
     rds_clear('Additional_DBSecurity_Groups')
     rds_clear('DBInstanceId')
     rds_clear('DBName')
     rds_clear('DBInstanceClass')
     rds_clear('AllocatedStorage')
     rds_clear('AvailabilityZone')
     rds_clear_false('MultiAZ')
     rds_clear('Engine')
     rds_clear('EngineVersion')
     rds_clear('MasterUsername')
     rds_clear('MasterUserPassword')
     rds_clear('PreferredMaintenanceWindow')
     rds_clear('DBParameterGroupName')
     rds_clear('BackupRetentionPeriod')
     rds_clear('PreferredBackupWindow')
     rds_clear('DBSnapshot')
     rds_clear('Port')
     rds_clear_true('AutoMinorVersionUpgrade')
     rds_clear_read_replica
     clear_notes     
     @launch_loaded = false
     #puts @rds_launch['Security_Group'].text
   end 
   
   def rds_clear_true(field)
      @properties[field] = ""
      @rds_launch[field].setCurrentItem(0)
   end 
   def rds_clear_false(field)
      @properties[field] = ""
      @rds_launch[field].setCurrentItem(1)
   end 
   
   def rds_clear(key)
      @properties[key] = ""
      @rds_launch[key].text = ""
   end  
   
   #def get(key)
   #   return @properties[key]
   #end
   
   def rds_put(key,value)
      puts "Launch.put "+key
      @properties[key] = value
      @rds_launch[key].text = value
   end 
   
   def rds_save
      puts "Launch.save"
      save_rds_launch('DBSecurity_Group')
      save_rds_launch('Additional_DBSecurity_Groups')
      save_rds_launch('DBInstanceId')
      save_rds_launch('DBName')
      save_rds_launch('DBInstanceClass')
      save_rds_launch('AllocatedStorage')
      save_rds_launch('AvailabilityZone')
      save_rds_launch_true_false('MultiAZ')
      save_rds_launch('Engine')
      save_rds_launch('EngineVersion')
      #save_ApplyImmediately
      save_rds_launch('MasterUsername')
      save_rds_launch('MasterUserPassword')
      save_rds_launch('PreferredMaintenanceWindow')
      save_rds_launch('DBParameterGroupName')
      save_rds_launch('BackupRetentionPeriod')
      save_rds_launch('PreferredBackupWindow')
      save_rds_launch('DBSnapshot')
      save_rds_launch('Port')
      save_rds_launch_true_false('AutoMinorVersionUpgrade')
      save_rds_read_replica
      doc = ""
      @properties.each_pair do |key, value|
       doc = doc + "#{key}=#{value}\n"
      end
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      if !File.directory?(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
      	  FileUtils.mkdir_p @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder
      end      
      File.open(fn, "w") do |f|
        f.write(doc)
      end
      save_notes
      @launch_loaded = true
   end
   
   def rds_delete
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      if File.exists?(fn)
         answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of DB launch profile "+@profile)
         if answer == MBOX_CLICKED_YES
           File.delete(fn)
           load_rds(@profile)
         end
      else
         error_message("Error","No DB Launch Profile for "+@profile+" to delete") 
      end    
   end 
   
   def save_rds_launch_true_false(field)
        if @rds_launch[field].itemCurrent?(0) 
	    @properties[field]="true"  
	else
	    @properties[field]="false" 
        end
   end
   
   def save_rds_launch(key)
     puts "Launch.save_setting"  
     if @rds_launch[key].text != nil
       @properties[key] =  @rds_launch[key].text
     else
       @properties[key] = nil
     end
   end

   def rds_clear_read_replica
      @read_replica = Array.new 
      @rds_launch['Read_Replicas'].clearItems
      @rds_launch['Read_Replicas'].rowHeaderWidth = 0	
      @rds_launch['Read_Replicas'].setTableSize(@read_replica.size, 1)
      @rds_launch['Read_Replicas'].setColumnText(0, "Read Replica Instance Id") 
      @rds_launch['Read_Replicas'].setColumnWidth(0,200)
   end

   def load_rds_read_replica
      @read_replica = Array.new 
      for i in 1..5 
         if @properties["ReadReplica_#{i}_db_instance_id"] != nil and @properties["ReadReplica_#{i}_db_instance_id"] != ""  
            rr = {} 
            rr[:db_instance_id] 	= @properties["ReadReplica_#{i}_db_instance_id"]
            rr[:source_db_instance_id] 	= @properties["ReadReplica_#{i}_source_db_instance_id"] 
            rr[:instance_class] 	= @properties["ReadReplica_#{i}_instance_class"]
            rr[:endpoint_port] 		= @properties["ReadReplica_#{i}_endpoint_port"]
            rr[:availability_zone] 	= @properties["ReadReplica_#{i}_availability_zone"]
 	    rr[:auto_minor_version_upgrade] = @properties["ReadReplica_#{i}_auto_minor_version_upgrade"] 
            @read_replica.push(rr)
         end   
      end
      load_rds_read_replica_table
   end
   
   def save_rds_read_replica
      i=0
      @read_replica.each do |rr|
         if rr!= nil
            i=i+1
            @properties["ReadReplica_#{i}_db_instance_id"] 		=  rr[:db_instance_id].to_s 
            @properties["ReadReplica_#{i}_source_db_instance_id"] 	=  rr[:source_db_instance_id]
            @properties["ReadReplica_#{i}_instance_class"] 		=  rr[:instance_class].to_s
            @properties["ReadReplica_#{i}_endpoint_port"] 		=  rr[:endpoint_port].to_s
            @properties["ReadReplica_#{i}_availability_zone"] 	=  rr[:availability_zone].to_s
 	    @properties["ReadReplica_#{i}_auto_minor_version_upgrade"] =  rr[:auto_minor_version_upgrade].to_s
          end
       end
   end

   def load_rds_read_replica_table
         @rds_launch['Read_Replicas'].clearItems
         @rds_launch['Read_Replicas'].rowHeaderWidth = 0	
         @rds_launch['Read_Replicas'].setTableSize(@read_replica.size, 1)
         @rds_launch['Read_Replicas'].setColumnText(0, "Read Replica Instance Id") 
         @rds_launch['Read_Replicas'].setColumnWidth(0,200)
         i = 0
         @read_replica.each do |m|
           if m!= nil 
              @rds_launch['Read_Replicas'].setItemText(i, 0, "#{m[:db_instance_id]}")
              @rds_launch['Read_Replicas'].setItemJustify(i, 0, FXTableItem::LEFT)
              i = i+1
   	     end 
         end
         @read_replica_curr_row = nil    
   end

#
#  as methods
#

 def launch_as_Panel(item)
     load_as(item.text)
 end 
 
 def load_as(sec_grp=nil)
      puts "Launch.load_as"
      @type = "as"
      @frame1.hide()
      @frame2.hide()
	@frame3.show()
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
