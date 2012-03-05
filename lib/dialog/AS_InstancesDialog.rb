
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

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
     	super(owner, "Instances for #{as_group}", :opts => DECOR_ALL, :width => 600, :height => 310)
    	@frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    	FXLabel.new(@frame1, "Auto Scaling Group" )
	@as_group_name = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
	@as_group_name.text = @as_name
    	FXLabel.new(@frame1, "" )
      FXLabel.new(@frame1, "Decrement Desired Capacity" )
	decrement_desired_capacity = FXComboBox.new(@frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
	decrement_desired_capacity.numVisible = 2      
	decrement_desired_capacity.appendItem("True")	
	decrement_desired_capacity.appendItem("False")
	decrement_desired_capacity.setCurrentItem(0)
      FXLabel.new(@frame1, "" )
      #  decrement_desired_capacity = FXCheckButton.new(@frame1,"Decrement Desired Capacity", :opts => ICON_BEFORE_TEXT|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
	#decrement_desired_capacity.setCheck(TRUE) 
      #  FXLabel.new(@frame1, "" )
      #  decrement_desired_capacity.connect(SEL_COMMAND) do
      #    if @decrement_capacity == false
      #       @decrement_capacity = true
      #   else
      #       @decrement_capacity = false
      #    end
      #  end         
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
       as = @ec2_main.environment.as_connection
       if as != nil
           begin
              as.terminate_instance_in_auto_scaling_group(instance_id, decrement_capacity)
              @updated = true
	      @curr_instance = ""
              describe_instances(as_group)
           rescue
              error_message("Terminate of Instance #{instance_id} Failed",$!.to_s)
           end 
       end
  end
  
  def describe_instances(as_group)
        as = @ec2_main.environment.as_connection
        if as != nil
         begin 
            as.describe_auto_scaling_groups(as_group).each do |r|
  		    load_instances_table(r[:instances])
            end 
         rescue
            error_message("Describe Auto Scaling Groups Failed",$!.to_s)
            return
         end
        end
  end
  
  def load_instances_table(r)
           @as_instances.clearItems
           @as_instances.rowHeaderWidth = 0	
           @as_instances.setTableSize(r.size, 3)
           @as_instances.setColumnText(0, "Instance Id")
           @as_instances.setColumnText(1, "Lifecycle State")
           @as_instances.setColumnText(2, "Availability Zone")
           @as_instances.setColumnWidth(0,120)
           @as_instances.setColumnWidth(1,120)
           @as_instances.setColumnWidth(2,130)
           i = 0
           r.each do |m|
             if m!= nil 
                @as_instances.setItemText(i, 0, "#{m[:instance_id]}")
                @as_instances.setItemText(i, 1, "#{m[:lifecycle_state]}")
                @as_instances.setItemText(i, 2, "#{m[:availability_zone]}")
                @as_instances.setItemJustify(i, 0, FXTableItem::LEFT)
                @as_instances.setItemJustify(i, 1, FXTableItem::LEFT)
                @as_instances.setItemJustify(i, 2, FXTableItem::LEFT)
                i = i+1
     	       end 
           end   
  end 
  
  
  def updated
    @updated
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
