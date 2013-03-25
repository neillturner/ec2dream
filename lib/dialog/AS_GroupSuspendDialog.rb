
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_GroupSuspendDialog < FXDialogBox

  def initialize(owner, item)
    puts "AS_GroupSuspendDialog.initialize"
    
    @ec2_main = owner
    scaling_processes_value = "All"
    @created = false
    super(owner, "Suspend AutoScaling Group Processes ", :opts => DECOR_ALL, :width => 450, :height => 120)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Auto Scaling Group")
    auto_scaling_group = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    auto_scaling_group.text = item
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Scaling Processes")
    scaling_processes = FXComboBox.new(frame1, 5, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    scaling_processes.numVisible = 9
    scaling_processes.appendItem("All");
    scaling_processes.appendItem("Launch");
    scaling_processes.appendItem("Terminate");
    scaling_processes.appendItem("HealthCheck");
    scaling_processes.appendItem("ReplaceUnhealthy");
    scaling_processes.appendItem("AZRebalance");
    scaling_processes.appendItem("AlarmNotification");
    scaling_processes.appendItem("ScheduledActions");
    scaling_processes.appendItem("AddToLoadBalancer");
    scaling_processes.connect(SEL_COMMAND) do |sender, sel, data|
       scaling_processes = data
    end    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    suspend = FXButton.new(frame1, "   &Suspend   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    suspend.connect(SEL_COMMAND) do |sender, sel, data|
      options = {}
      if scaling_processes_value != "All"
         options['ScalingProcesses'] = scaling_processes_value
      end     
      suspend_processes(auto_scaling_group.text, options)
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end 
  
  def suspend_processes(auto_scaling_group_name, options = {})
         begin 
            @ec2_main.environment.auto_scaling_groups.suspend_processes(auto_scaling_group_name, options)
            @created = true
         rescue
            error_message("Scaling Group Processes Suspend failed",$!)
         end
  end    
  
  def saved
     @created
  end
  
  def suspended
     @created
  end
  
  def success
     @created
  end

end
