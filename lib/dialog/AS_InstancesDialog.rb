require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/AS_CapacityDialog'


include Fox

class AS_InstancesDialog < FXDialogBox

  def initialize(owner, as_group)
    puts "ASInstancesDialog.initialize"
    @ec2_main = owner
    @updated = false
    @as_name = as_group
    @curr_instance = ""
    @decrement_capacity = true
    @curr_row = nil
    @viewstack = @ec2_main.makeIcon("viewstack.png")
    @viewstack.create
    @curr_desired_capacity = "0"
    super(owner, "Instances for #{as_group}", :opts => DECOR_ALL, :width => 850, :height => 310)
    @frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "Auto Scaling Group" )
    @as_group_name = FXTextField.new(@frame1, 90, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    @as_group_name.text = @as_name
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Decrement Desired Capacity" )
    @frame1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    decrement_desired_capacity = FXComboBox.new(@frame1a, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    decrement_desired_capacity.numVisible = 2      
    decrement_desired_capacity.appendItem("True")	
    decrement_desired_capacity.appendItem("False")
    decrement_desired_capacity.setCurrentItem(0)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Instances")
    @as_instances = FXTable.new(@frame1,:height => 200, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_READONLY  )
    @header1 = @as_instances.columnHeader
    @header1.connect(SEL_COMMAND) do |sender, sel, which|
      # do nothing
    end
    @as_instances.connect(SEL_COMMAND) do |sender, sel, which|
      @curr_row = which.row
      @as_instances.selectRow(@curr_row)
      @curr_instance = @as_instances.getItemText(@curr_row, 0)
    end
    @frame1z = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    @delete_button = FXButton.new(@frame1z, " ",:opts => BUTTON_TOOLBAR)
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create
    @delete_button.icon = @delete
    @delete_button.tipText = "  Terminate Instance  "
    @delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @curr_row == nil
        error_message("No Instance selected","No Instance selected to terminate")
      else
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Instance "+@curr_instance)
        if answer == MBOX_CLICKED_YES 
          if decrement_desired_capacity.itemCurrent?(1)
            @decrement_capacity = false
          else 
            @decrement_capacity = true          
          end
          terminate_instance(@as_name, @curr_instance, @decrement_capacity)
        end   
      end 
    end
    @delete_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @arrow_refresh = @ec2_main.makeIcon("arrow_refresh.png")
    @arrow_refresh.create
    @refresh_button = FXButton.new(@frame1z, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @refresh_button.icon = @arrow_refresh
    @refresh_button.tipText = "Refresh Instances"
    @refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
      describe_instances(@as_name)
    end
    @refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @capacity_button = FXButton.new(@frame1z, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @capacity_button.icon = @viewstack
    @capacity_button.tipText = " Set Desired Capacity "
    @capacity_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = AS_CapacityDialog.new(@ec2_main, @as_name, @curr_desired_capacity)
      dialog.execute
    end 
    @capacity_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end 	
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )	
    FXLabel.new(@frame1, "" )
    exit_button = FXButton.new(@frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(@frame1, "" )
    exit_button.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    describe_instances(@as_name)
  end 
  def terminate_instance(as_group, instance_id, decrement_capacity)
    begin
      @ec2_main.environment.auto_scaling_groups.terminate_instance_in_auto_scaling_group(instance_id, decrement_capacity)
      @updated = true
      @curr_instance = ""
      describe_instances(as_group)
    rescue
      error_message("Terminate of Instance #{instance_id} Failed",$!)
    end 
  end
  def describe_instances(as_group)
    begin 
      r = @ec2_main.environment.auto_scaling_groups.get(as_group)
      @curr_desired_capacity  = r[:desired_capacity].to_s
      load_instances_table(r[:instances])
    rescue
      error_message("Describe Auto Scaling Groups Failed",$!)
    end
  end
  def load_instances_table(r)
    @as_instances.clearItems
    @as_instances.rowHeaderWidth = 0	
    @as_instances.setTableSize(r.size, 5)
    @as_instances.setColumnText(0, "Instance Id")
    @as_instances.setColumnText(1, "Lifecycle State")
    @as_instances.setColumnText(2, "Availability Zone")
    @as_instances.setColumnText(3, "Health Status")
    @as_instances.setColumnText(4, "Launch Config Name")
    @as_instances.setColumnWidth(0,100)
    @as_instances.setColumnWidth(1,100)
    @as_instances.setColumnWidth(2,130)
    @as_instances.setColumnWidth(3,120)
    @as_instances.setColumnWidth(4,140)
    i = 0
    r.each do |m|
      if m!= nil 
        @as_instances.setItemText(i, 0, "#{m.id}")
        @as_instances.setItemText(i, 1, "#{m.life_cycle_state}")
        @as_instances.setItemText(i, 2, "#{m.availability_zone}")
        @as_instances.setItemText(i, 3, "#{m.health_status}")
        @as_instances.setItemText(i, 4, "#{m.launch_configuration_name}")
        @as_instances.setItemJustify(i, 0, FXTableItem::LEFT)
        @as_instances.setItemJustify(i, 1, FXTableItem::LEFT)
        @as_instances.setItemJustify(i, 2, FXTableItem::LEFT)
        @as_instances.setItemJustify(i, 3, FXTableItem::LEFT)
        @as_instances.setItemJustify(i, 4, FXTableItem::LEFT)
        i = i+1
      end 
    end   
  end 
  def saved
    @updated
  end
  def updated
    @updated
  end

  def success
    @updated
  end
end
