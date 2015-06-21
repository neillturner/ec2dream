require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_PolicyEditDialog < FXDialogBox

  def initialize(owner, item=nil, as_group="")
    puts "ASPolicyEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
      @result = ""
      @title = "Add Policy"
    else
      @result = item
      @title = "Edit Policy"
    end
    @saved = false
    @as_name = as_group
    @as_alarms = Array.new
    @as_alarms_curr_row = nil
    @dim = nil
    @create = @ec2_main.makeIcon("new.png")
    @create.create    
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create
    adjustment_type_value = ""
    super(owner, @title, :opts => DECOR_ALL, :width => 650, :height => 300)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Auto Scaling Group" )
    group_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    group_name.text = @as_name
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Policy Name" )
    policy_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Cooldown" )
    cooldown = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Adjustment Type" )
    adjustment_type = FXComboBox.new(frame1, 5, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    adjustment_type.numVisible = 3
    adjustment_type.appendItem("ChangeInCapacity");
    adjustment_type.appendItem("ExactCapacity");
    adjustment_type.appendItem("PercentChangeInCapacity");
    adjustment_type.connect(SEL_COMMAND) do |sender, sel, data|
      adjustment_type_value = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Scaling Adjustment" )
    scaling_adjustment = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Alarms")
    alarms = FXTable.new(frame1,:height => 80, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    alarms.connect(SEL_COMMAND) do |sender, sel, which|
      @as_alarms_curr_row = which.row
      alarms.selectRow(@as_alarms_curr_row)
    end 
    FXLabel.new(frame1, "" )  
    FXLabel.new(frame1, "" )  
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Policy ARN" )
    policy_arn = FXTextField.new(frame1, 80, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )  
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame2, "" )
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      if policy_name.text == nil or policy_name.text == ""
        error_message("Error","Policy Name not specified")
      else
        @options = {}
        @options['Cooldown']=(cooldown.text).to_i
        @options['Alarm']=@as_alarms
        put_scaling_policy(adjustment_type_value, group_name.text, policy_name.text, scaling_adjustment.text, @options)
        if @saved == true
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end         
      end  
    end
    if @result != ""
      options = {} 
      options['AutoScalingGroupName'] = group_name.text
      options['PolicyName'] = @result
      @ec2_main.environment.auto_scaling_policies.all(options).each do |r|
        if r['PolicyName'] == @result
          policy_name.text = r['PolicyName']
          policy_arn.text = r['PolicyARN']
          cooldown.text = r['Cooldown'].to_s
          adjustment_type_value = r['AdjustmentType']
          adjustment_type.setCurrentItem(0)
          if adjustment_type_value == "ExactCapacity"
            adjustment_type.setCurrentItem(1)
          end
          if adjustment_type_value == "PercentChangeInCapacity"
            adjustment_type.setCurrentItem(2)
          end       		
          scaling_adjustment.text = r['ScalingAdjustment'].to_s
          @as_alarms = r['Alarms']
          load_alarm_table(alarms)
        else
          @as_alarms = r['Alarms']
          load_alarm_table(alarms)
        end
      end
    else
      adjustment_type_value = "ChangeInCapacity"
      load_alarm_table(alarms)
    end
  end 
  def put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options = {})
    begin
      puts "options #{options}" 
      r = @ec2_main.environment.auto_scaling_policies.put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options)
      @saved = true
    rescue
      error_message("Create or Update Policy Failed",$!)
    end 
  end 

  def load_alarm_table(field)
    field.clearItems
    field.rowHeaderWidth = 0	
    field.setTableSize(@as_alarms.size, 1)
    field.setColumnText(0, "Alarm Name;Alarm ARN") 
    field.setColumnWidth(0,350)
    i = 0
    @as_alarms.each do |m|
      if m!= nil 
        field.setItemText(i, 0, "#{m['AlarmName']};#{m['AlarmARN']}")
        field.setItemJustify(i, 0, FXTableItem::LEFT)
        i = i+1
      end 
    end   
  end

  def saved
    @saved
  end
  def success
    @saved
  end

end
