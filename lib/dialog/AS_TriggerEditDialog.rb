require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/AS_TriggerDimensionDialog'
require 'dialog/AS_TriggerFieldsDialog'
include Fox

class AS_TriggerEditDialog < FXDialogBox

  def initialize(owner, as_group, item=nil)
    puts "ASTriggerCreateDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
       @result = ""
       @title = "Add Trigger"
    else
       @result = item
       @title = "Edit Trigger"
    end
    @saved = false
    @as_name = as_group
    @dim = nil
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(owner, @title, :opts => DECOR_ALL, :width => 600, :height => 380)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Trigger Name" )
    trigger_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Measure Name" )
    measure_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    measure_name_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    measure_name_button.icon = @magnifier
    measure_name_button.tipText = " Select Measure Name "
    measure_name_button.connect(SEL_COMMAND) do
	@dialog = AS_TriggerFieldsDialog.new(@ec2_main,"Measure")
	@dialog.execute
	if @dialog.selected != nil and @dialog.selected != ""
	   measure_name.text = @dialog.selected
	end   
    end    

    FXLabel.new(frame1, "Statistic" )
    statistic = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    statistic_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    statistic_button.icon = @magnifier
    statistic_button.tipText = " Select Statistic "
    statistic_button.connect(SEL_COMMAND) do
	@dialog = AS_TriggerFieldsDialog.new(@ec2_main,"Statistic")
	@dialog.execute
	if @dialog.selected != nil and @dialog.selected != ""
	   statistic.text = @dialog.selected
	end   
    end 

    FXLabel.new(frame1, "Period (Secs)" )
    period = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Lower Threshold" )
    lower_threshold = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Lower Breach Scale Increment" )
    lower_breach_scale_increment = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Upper Threshold" )
    upper_threshold = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Upper Breach Scale Increment" )
    upper_breach_scale_increment = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Breach Duration (Secs)" )
    breach_duration = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Unit" )
    unit = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    unit_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    unit_button.icon = @magnifier
    unit_button.tipText = "Select Unit"
    unit_button.connect(SEL_COMMAND) do
	@dialog = AS_TriggerFieldsDialog.new(@ec2_main,"Unit")
	@dialog.execute
	if @dialog.selected != nil and @dialog.selected != ""
	   unit.text = @dialog.selected
	end   
    end  

    FXLabel.new(frame1, "Custom Unit" )
    custom_unit = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Dimensions" )
    dimensions = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY )
    dimensions_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    dimensions_button.icon = @edit
    dimensions_button.tipText = "Edit Dimensions"
    dimensions_button.connect(SEL_COMMAND) do
	@dialog = AS_TriggerDimensionDialog.new(@ec2_main,@dim)
	@dialog.execute
	if @dialog.saved
         @dim = @dialog.dimensions
	   dimensions.text = dim_show 
	end   
    end  
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       if trigger_name.text == nil or trigger_name.text == ""
         error_message("Error","Trigger Name not specified")
       else
         @options = {}
         @dim = {}         
         @options[:measure_name]=measure_name.text if  measure_name.text != ""
         @options[:statistic]=statistic.text if statistic.text != ""
         @options[:period]=period.text if  period.text != ""
         @options[:lower_threshold]=lower_threshold.text if  lower_threshold.text != ""
         @options[:lower_breach_scale_increment]=lower_breach_scale_increment.text if  lower_breach_scale_increment.text != ""
         @options[:upper_threshold]=upper_threshold.text if  upper_threshold.text != ""
         @options[:upper_breach_scale_increment]=upper_breach_scale_increment.text if  upper_breach_scale_increment.text != ""
         @options[:breach_duration]=breach_duration.text if  breach_duration.text != ""
         @options[:unit]=unit.text if  unit.text != ""
         @options[:custom_unit]=custom_unit.text if  custom_unit.text != ""
	 @dim["AutoScalingGroupName"]= @as_name 
         @dim["Namespace"]="AWS"
         @dim["Service"]="EC2"
         # or should it be @options[:namespace]="AWS/EC2" and need to change right_as_interface?
         @options[:dimensions] = @dim 
         save_trigger(trigger_name.text, @as_name , @options)
         if @saved == true
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end         
       end  
    end
    if @result != ""
       as = @ec2_main.environment.as_connection
       if as != nil 
          as.describe_triggers(@as_name).each do |r|
             if r[:trigger_name] = @result
        		measure_name.text = r[:measure_name]
        		breach_duration.text = r[:breach_duration].to_s
        		upper_breach_scale_increment.text = r[:upper_breach_scale_increment].to_s
        		upper_threshold.text = r[:upper_threshold].to_s
        		lower_threshold.text = r[:lower_threshold].to_s
        		lower_breach_scale_increment.text = r[:lower_breach_scale_increment].to_s
        		period.text = r[:period].to_s
        		trigger_name.text = r[:trigger_name]
        		statistic.text = r[:statistic]
        		unit.text = r[:unit]
                  @dim = r[:dimensions]
			dimensions.text = dim_show
                  trigger_name.editable = false 
               end
          end
       end
     else
        period.text = "60"
        unit.text = "None"
        lower_threshold.text = "0"
        lower_breach_scale_increment.text = "1"
        upper_threshold.text = "60"
        upper_breach_scale_increment.text = "1"
        breach_duration.text = "300"
        statistic.text = "Average"
     end
  end 
  
  def save_trigger(trigger_name, auto_scaling_group_name, options)
     as = @ec2_main.environment.as_connection
     if as != nil
      begin
       puts "options #{options}" 
       r = as.create_or_update_scaling_trigger(trigger_name, auto_scaling_group_name, options)
       @saved = true
      rescue
        error_message("Create or Update Trigger Failed",$!.to_s)
      end 
     end
  end 

  def dim_show
     dim_str = ""   
     if @dim != nil 
        @dim.each_pair do |k,v|
          if dim_str == ""
            dim_str = "#{k}=#{v}" 
          else
            dim_str = dim_str + " #{k}=#{v}" 
          end
        end
     end
     return dim_str
  end    

  #def assign_option(field,field_name)
  #   if field != nil and field != "" 
  #      @options[field_name]=field
  #   end
  #end

  def saved
     @saved
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end

end
