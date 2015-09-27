require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_SecGrp_SelectDialog'
require 'dialog/EC2_ImageDialog'
require 'dialog/EC2_ImageAttributeDialog'
require 'dialog/EC2_InstanceDialog'
require 'dialog/EC2_KeypairDialog'
require 'common/EC2_Block_Mapping'
require 'dialog/AS_BlockMappingEditDialog'
require 'common/error_message'

include Fox

class AS_LaunchConfigurationCreateDialog < FXDialogBox

  def initialize(owner, item=nil)
    puts "ASLaunchConfigurationCreateDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil
      @result = ""
      @title = "Add Launch Configuration"
    else
      @result = item
      @title = "Edit Launch Configuration"
    end
    @as_bm = EC2_Block_Mapping.new
    @saved = false
    @create = @ec2_main.makeIcon("new.png")
    @create.create
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create
    @view = @ec2_main.makeIcon("application_view_icons.png")
    @view.create
    super(owner, @title, :opts => DECOR_ALL, :width => 650, :height => 500)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Launch Config Name" )
    launch_configuration_name = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Created Time" )
    created_time = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Security Groups" )
    security_groups = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    security_group_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    security_group_button.icon = @magnifier
    security_group_button.tipText = "Select Security Group"
    security_group_button.connect(SEL_COMMAND) do
      dialog = EC2_SecGrp_SelectDialog.new(@ec2_main)
      dialog.execute
      selected = dialog.sec_grp
      if selected != nil and selected != ""
        security_groups.text = selected
      end
    end
    FXLabel.new(frame1, "Image Id" )
    image_id = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    frame1z = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    image_id_button = FXButton.new(frame1z, "", :opts => BUTTON_TOOLBAR)
    image_id_button.icon = @magnifier
    image_id_button.tipText = "Select Image"
    image_id_button.connect(SEL_COMMAND) do
      dialog = EC2_ImageDialog.new(@ec2_main)
      dialog.execute
      selected = dialog.selected
      if selected != nil and selected != ""
        image_id.text = selected
      end
    end
    attributes_button = FXButton.new(frame1z, " ",:opts => BUTTON_TOOLBAR)
    attributes_button.icon = @view
    attributes_button.tipText = "  Image Attributes  "
    attributes_button.connect(SEL_COMMAND) do |sender, sel, data|
      @curr_item = image_id.text
      if @curr_item == nil or @curr_item == ""
        error_message("No Image Id","No Image Id specified to display attributes")
      else
        dialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
        dialog.execute
      end
    end
    FXLabel.new(frame1, "Kernel Id" )
    kernel_id = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "RamdiskId" )
    ramdisk_id = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    # not available yet
    #FXLabel.new(frame1, "Spot Price" )
    #SpotPrice = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    #FXLabel.new(frame1, "" )
    #FXLabel.new(frame1, "Iam Instance Profile" )
    #IamInstanceProfile = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    #FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "UserData" )
    #UserData = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    user_data = FXText.new(frame1, :height => 150, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Instance Type" )
    frame1d = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    instance_type = FXTextField.new(frame1d, 25, nil, 0, :opts => FRAME_SUNKEN)
    instance_type_button = FXButton.new(frame1d, "", :opts => BUTTON_TOOLBAR)
    instance_type_button.icon = @magnifier
    instance_type_button.tipText = "Select Instance Type"
    instance_type_button.connect(SEL_COMMAND) do
      dialog = EC2_InstanceDialog.new(@ec2_main)
      dialog.execute
      type = dialog.selected
      if type != nil and type != ""
        instance_type.text = type
      end
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "KeyName" )
    frame1e = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    keyname = FXTextField.new(frame1e, 25, nil, 0, :opts => FRAME_SUNKEN)
    keyname_button = FXButton.new(frame1e, "", :opts => BUTTON_TOOLBAR)
    keyname_button.icon = @magnifier
    keyname_button.tipText = "Select Keypair"
    keyname_button.connect(SEL_COMMAND) do
      dialog = EC2_KeypairDialog.new(@ec2_main)
      dialog.execute
      keypair = dialog.selected
      if keypair != nil and keypair != ""
        keyname.text=keypair
      end
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Instance Monitoring" )
    instance_monitoring = FXComboBox.new(frame1, 25, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    instance_monitoring.numVisible = 2
    instance_monitoring.appendItem("true")
    instance_monitoring.appendItem("false")
    instance_monitoring.setCurrentItem(0)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Block Device Mappings")
    block_device_mappings = FXTable.new(frame1,:height => 40, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    block_device_mappings.connect(SEL_COMMAND) do |sender, sel, which|
      @as_bm.set_curr_row(which.row)
      block_device_mappings.selectRow(@as_bm.curr_row)
    end
    page1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    block_device_mappings_create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    block_device_mappings_create_button.icon = @create
    block_device_mappings_create_button.tipText = "  Add Block Device  "
    block_device_mappings_create_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = AS_BlockMappingEditDialog.new(@ec2_main,nil)
      dialog.execute
      if dialog.saved
        bm = dialog.block_mapping
        @as_bm.push(bm)
        @as_bm.load_table(block_device_mappings)
      end
    end
    block_device_mappings_create_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    block_device_mappings_edit_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    block_device_mappings_edit_button.icon = @edit
    block_device_mappings_edit_button.tipText = "  Edit Block Device  "
    block_device_mappings_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @as_bm.curr_row == nil
        error_message("No Block Device selected","No Block Device selected to edit")
      else
        dialog = AS_BlockMappingEditDialog.new(@ec2_main,@as_bm.get)
        dialog.execute
        if dialog.saved
          bm = dialog.block_mapping
          @as_bm.update(bm)
          @as_bm.load_table(block_device_mappings)
        end
      end
    end
    block_device_mappings_delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    block_device_mappings_delete_button.icon = @delete
    block_device_mappings_delete_button.tipText = "  Delete Block Device  "
    block_device_mappings_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @as_bm.curr_row == nil
        error_message("No Block Device selected","No Block Device selected to delete")
      else
        m = @as_bm.get
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Block Device #{m[:device_name]}")
        if answer == MBOX_CLICKED_YES
          @as_bm.delete
          @as_bm.load_table(block_device_mappings)
        end
      end
    end
    block_device_mappings_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame2, "" )
    save = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame2, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      if launch_configuration_name.text == nil or launch_configuration_name.text == ""
        error_message("Error","Launch Configuration Name not specified")
      else
        @instance_monitoring_value = false
        if instance_monitoring.itemCurrent?(0)
         @instance_monitoring_value = true
        end
        create_launch_configuration(launch_configuration_name.text, instance_type.text, image_id.text, security_groups.text, kernel_id.text, ramdisk_id.text, user_data.text, keyname.text)
        if @saved == true
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
      end
    end
    if @result != ""
      begin
        r = @ec2_main.environment.launch_configurations.get(@result)
        created_time.text = r[:created_time]
        security_groups.text = ""
        r[:security_groups].each do |a|
          if security_groups.text =""
            security_groups.text = a
          else
            security_groups.text = security_groups.text + ",#{a}"
          end
        end
        image_id.text = r[:image_id]
        kernel_id.text  = r[:kernel_id]
        ramdisk_id.text = r[:ramdisk_id]
        user_data.text = r[:user_data]
        if r[:user_data]!=nil and r[:user_data]!=""
          user_data.text = Base64.decode64(r[:user_data])
        else
          user_data.text = ""
        end
        instance_type.text = r[:instance_type]
        keyname.text = r[:key_name]
        if r[:instance_monitoring] == true
          instance_monitoring.setCurrentItem(0)
        else
          instance_monitoring.setCurrentItem(1)
        end
        @as_bm.load_fog(r,block_device_mappings )
      rescue
        error_message("Loading Launch Configuration Failed",$!)
      end
    end
  end

  def create_launch_configuration(launch_configuration_name, instance_type, image_id, security_groups, kernel_id, ramdisk_id, user_data, key_name)
    puts "ASLaunchConfigurationCreateDialog.create_launch_configuration"
    r = {}
    r['SecurityGroups'] = security_groups
    r['KernelId'] = kernel_id  if kernel_id != nil and kernel_id != ""
    r['RamdiskId'] = ramdisk_id if ramdisk_id != nil and ramdisk_id != ""
    r['UserData'] = user_data if user_data != nil and user_data != ""
    r['KeyName'] = key_name
    r['BlockDeviceMappings'] = @as_bm.array_fog if @as_bm.size > 0
    r['InstanceMonitoring.Enabled'] = @instance_monitoring_value
    begin
      @ec2_main.environment.launch_configurations.create_launch_configuration(image_id, instance_type, launch_configuration_name,  r)
      @saved = true
    rescue
      error_message("Create Launch Configuration Failed",$!)
    end
  end

  def saved
    @saved
  end

  def success
    @saved
  end

end
