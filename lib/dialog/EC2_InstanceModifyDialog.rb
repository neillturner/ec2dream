require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/EC2_SecGrp_SelectDialog'
require 'cache/EC2_ServerCache'

include Fox

class EC2_InstanceModifyDialog < FXDialogBox

  def initialize(owner, instance_id)
    puts "InstanceModifyDialog.initialize"
    @ec2_main = owner
    @modified = false
    @add = @ec2_main.makeIcon("add.png")
    @add.create
    @cross = @ec2_main.makeIcon("cross.png")
    @cross.create
    @orig_server = {}
    @server = {}
    @ec2_main.serverCache.refresh(instance_id)
    @cache = @ec2_main.serverCache.instance(instance_id)
    super(owner, "Modify Instance", :opts => DECOR_ALL, :width => 600, :height => 350)
    @page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    @frame1 = FXMatrix.new(@page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "Instance ID" )
    @server['Instance_ID'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Instance_ID'].text = instance_id
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Security_Groups" )
    @server['Security_Group'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Security_Group'].text = @ec2_main.serverCache.instance_groups_list(instance_id)
    @orig_server['Security_Group'] = @server['Security_Group'].text
    @frame1x = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @server['Security_Group_Button'] = FXButton.new(@frame1x, "", :opts => BUTTON_TOOLBAR)
    @server['Security_Group_Button'].icon = @add
    @server['Security_Group_Button'].tipText = "Add Security Group"
    @server['Security_Group_Button'].connect(SEL_COMMAND) do
      dialog = EC2_SecGrp_SelectDialog.new(@ec2_main)
      dialog.execute
      selected = dialog.sec_grp
      if selected != nil and selected != ""
        current_sec_grp = @server['Security_Group'].text
        if current_sec_grp != nil and current_sec_grp != ""
          selected = "#{current_sec_grp},#{selected}"
        end
        @server['Security_Group'].text=selected
      end
    end
    @server['Security_Group_Button_Delete'] = FXButton.new(@frame1x, "", :opts => BUTTON_TOOLBAR)
    @server['Security_Group_Button_Delete'].icon = @cross
    @server['Security_Group_Button_Delete'].tipText = "Remove Security Group"
    @server['Security_Group_Button_Delete'].connect(SEL_COMMAND) do
      dialog = EC2_SecGrp_SelectDialog.new(@ec2_main,"ec2",@server['Security_Group'].text)
      dialog.execute
      selected = dialog.sec_grp
      if selected != nil and selected != ""
        sa = (@server['Security_Group'].text).split","
        sa.delete_if {|s| s == selected }
        @server['Security_Group'].text =sa.join(",")
      end
    end
    FXLabel.new(@frame1x, "" )
    FXLabel.new(@frame1, "Disable Api Termination" )
    @server['Disable_Api_Termination'] = FXComboBox.new(@frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @server['Disable_Api_Termination'].numVisible = 2
    @server['Disable_Api_Termination'].appendItem("true")
    @server['Disable_Api_Termination'].appendItem("false")
    @server['Disable_Api_Termination'].setCurrentItem(0)
    disable_api = get_attribute(instance_id,"disableApiTermination")
    disable_api = disable_api.to_s
    @orig_server['Disable_Api_Termination'] = disable_api
    if disable_api == "true"
      @server['Disable_Api_Termination'].setCurrentItem(0)
    else
      @server['Disable_Api_Termination'].setCurrentItem(1)
    end
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "  Instance Init Shutdown" )
    @server['Instance_Initiated_Shutdown_Behavior'] = FXComboBox.new(@frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @server['Instance_Initiated_Shutdown_Behavior'].numVisible = 2
    @server['Instance_Initiated_Shutdown_Behavior'].appendItem("stop")
    @server['Instance_Initiated_Shutdown_Behavior'].appendItem("terminate")
    @server['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(0)
    instance_init_shut = get_attribute(instance_id,"instanceInitiatedShutdownBehavior")
    instance_init_shut = instance_init_shut.to_s
    @orig_server['Instance_Initiated_Shutdown_Behavior'] = instance_init_shut
    if instance_init_shut == "stop"
      @server['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(0)
    else
      @server['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(1)
    end
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "  Source/Dest Check" )
    @server['Source_Dest_Check'] = FXComboBox.new(@frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @server['Source_Dest_Check'].numVisible = 2
    @server['Source_Dest_Check'].appendItem("true")
    @server['Source_Dest_Check'].appendItem("false")
    @server['Source_Dest_Check'].setCurrentItem(0)
    source_dest_check = get_attribute(instance_id,"sourceDestCheck")
    source_dest_check = source_dest_check.to_s
    @orig_server['Source_Dest_Check'] = source_dest_check
    if source_dest_check == "true"
      @server['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(0)
    else
      @server['Instance_Initiated_Shutdown_Behavior'].setCurrentItem(1)
    end
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Root Device Name" )
    @server['Root_Device_Name'] = FXTextField.new(@frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    @server['Root_Device_Name'].text = get_attribute(instance_id,"rootDeviceName")
    @orig_server['Root_Device_Name'] = @server['Root_Device_Name'].text
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "To modify following instance must be stopped" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Instance Type" )
    @server['Instance_Type'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    @server['Instance_Type'].text = get_attribute(instance_id,"instanceType")
    @orig_server['Instance_Type'] = @server['Instance_Type'].text
    @server['Instance_Type_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @server['Instance_Type_Button'].icon = @magnifier
    @server['Instance_Type_Button'].tipText = "Select Instance Type"
    @server['Instance_Type_Button'].connect(SEL_COMMAND) do
      @dialog = EC2_InstanceDialog.new(@ec2_main)
      @dialog.execute
      type = @dialog.selected
      if type != nil and type != ""
        @server['Instance_Type'].text = type
      end
    end
    FXLabel.new(@frame1, "Kernel" )
    @server['Kernel'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    @server['Kernel'].text = get_attribute(instance_id,"kernelId")
    @orig_server['Kernel'] = @server['Kernel'].text
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Ramdisk" )
    @server['Ramdisk'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    @server['Ramdisk'].text = get_attribute(instance_id,"ramdiskId")
    @orig_server['Ramdisk'] = @server['Ramdisk'].text
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "User Data" )
    @server['User_Data'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    @server['User_Data'].text = "" # get_attribute(instance_id,"userData")
    @orig_server['User_Data'] = @server['User_Data'].text
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "User Data File")
    @server['User_Data_File'] = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    @server['User_Data_File_Button'] = FXButton.new(@frame1, "", :opts => BUTTON_TOOLBAR)
    @server['User_Data_File_Button'].icon = @magnifier
    @server['User_Data_File_Button'].tipText = "Browse..."
    @server['User_Data_File_Button'].connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(@frame1, "Select User Data file")
      dialog.patternList = [
        "Pem Files (*.*)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        @server['User_Data_File'].text = dialog.filename
      end
    end
    @frame2 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    @frame2 = FXHorizontalFrame.new(@page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(@frame2, "" )
    modify = FXButton.new(@frame2, "   &Modify   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(@frame2, "" )
    modify.connect(SEL_COMMAND) do |sender, sel, data|
      modify_instance
      if @modified == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end
    def modify_instance
    modify_attribute(@server['Instance_ID'].text,'InstanceType.Value',@server['Instance_Type'].text, @orig_server['Instance_Type'])
    modify_attribute(@server['Instance_ID'].text,'GroupId',@server['Security_Group'].text, @orig_server['Security_Group'])
    modify_attribute(@server['Instance_ID'].text,'Kernel.Value',@server['Kernel'].text, @orig_server['Kernel'])
    modify_attribute(@server['Instance_ID'].text,'Ramdisk.Value',@server['Ramdisk'].text, @orig_server['Ramdisk'])
    modify_attribute(@server['Instance_ID'].text,'UserData.Value',@server['User_Data'].text, @orig_server['User_Data'])
    if @server['User_Data_File'].text != nil and @server['User_Data_File'].text != ""
      fn = @server['User_Data_File'].text
      d = ""
      begin
        f = File.open(fn, "r")
        d = f.read
        f.close
      rescue
        puts "ERROR: could not read user data file"
        error_message("Attribute Error","Could not read User Data File")
        return
      end
      modify_attribute(@server['Instance_ID'].text,'UserData.Value',d,"")
    end
    disable_api = "true"
    if @server['Disable_Api_Termination'].itemCurrent?(1)
      disable_api = "false"
    end
    modify_attribute(@server['Instance_ID'].text,'DisableApiTermination.Value',disable_api, @orig_server['Disable_Api_Termination'])
    instance_init_shut = "stop"
    if @server['Instance_Initiated_Shutdown_Behavior'].itemCurrent?(1)
      instance_init_shut = "terminate"
    end
    modify_attribute(@server['Instance_ID'].text,'InstanceInitiatedShutdownBehavior.Value',instance_init_shut, @orig_server['Instance_Initiated_Shutdown_Behavior'])
    #modify_attribute(@server['Instance_ID'].text,'RootDeviceName',@server['Root_Device_Name'].text, @orig_server['Root_Device_Name'])
  end

  def modify_attribute(instance,attr,value,orig_value)
    if orig_value != value
      begin
        puts "attr #{attr} value #{value} orig_value #{orig_value}"
        if attr == 'GroupId'
          sa = (value).split","
          gi = []
          vpc = get_attribute(instance,'vpcId')
          if vpc == nil
            error_message('Error','Can only change security groups of instances in vpcs')
            return
          end
          sa.each do |s|
            r=@ec2_main.serverCache.secGrps(s,vpc)
            gi.push(r[:group_id]) if r != nil
            if r == nil
              error_message('Error', 'Group #{s} not found in vpc #{vpc} try refreshing')
              return
            end
          end
          @ec2_main.environment.servers.modify_instance_attribute(instance,attr,gi)
        elsif attr == 'DisableApiTermination.Value'
          bvalue = false
          bvalue = true if attr == 'DisableApiTermination.Value' and value == "true"
          @ec2_main.environment.servers.modify_instance_attribute(instance,attr,bvalue)
        else
          @ec2_main.environment.servers.modify_instance_attribute(instance,attr,value)
        end
        orig_value = value
        @modified = true
      rescue
        error_message("Modify Instance Attribute Failed",$!)
      end
    end
  end
    def get_attribute(instance,attr)
    value = ""
    if @cache != nil and @cache != ""
      value = @cache[attr] if @cache[attr] != nil
      puts "instance attribute #{attr} not found" if @cache[attr] == nil
    else
      error_message("Instance Error","Instance #{instance} not found")
    end
    return value
  end
  def saved
    @modified
  end
  def modified
    @modified
  end
  def success
    @modified
  end
end
