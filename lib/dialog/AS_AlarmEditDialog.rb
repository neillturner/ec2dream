require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
include Fox
require 'dialog/AS_MetricDialog'
require 'dialog/AS_UnitDialog'
require 'dialog/AS_NamespaceDialog'
require 'dialog/AS_PolicyDialog'
require 'common/error_message'

class AS_AlarmEditDialog < FXDialogBox

  def initialize(owner, item=nil)
    puts "ASAlarmEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
      @result = ""
      @title = "Add CloudWatch Alarm"
    else
      @result = item
      @title = "Edit CloudWatch Alarm"
    end
    @saved = false
    #@create = @ec2_main.makeIcon("new.png")
    #@create.create    
    #@edit = @ec2_main.makeIcon("application_edit.png")
    #@edit.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    #@delete = @ec2_main.makeIcon("kill.png")
    #@delete.create
    comparison_operator_value = ""
    statistic_value = ""
    actions_enabled_value = "True"
    super(owner, @title, :opts => DECOR_ALL, :width => 600, :height => 600)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Alarm Name")
    alarm_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Alarm Description")
    alarm_description = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Namespace")
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    namespace = FXTextField.new(frame1a, 15, nil, 0, :opts => FRAME_SUNKEN)
    namespace_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    namespace_button.icon = @magnifier
    namespace_button.tipText = "Select Namespace"
    namespace_button.connect(SEL_COMMAND) do
      dialog = AS_NamespaceDialog.new(@ec2_main)
      dialog.execute
      if dialog.selected != nil and dialog.selected != ""
        namespace.text = dialog.selected
      end   
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Metric Name")
    frame1b = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    metric_name = FXTextField.new(frame1b, 20, nil, 0, :opts => FRAME_SUNKEN)
    metric_name_button = FXButton.new(frame1b, "", :opts => BUTTON_TOOLBAR)
    metric_name_button.icon = @magnifier
    metric_name_button.tipText = "Select Metric"
    metric_name_button.connect(SEL_COMMAND) do
      dialog = AS_MetricDialog.new(@ec2_main, namespace.text)
      dialog.execute
      if dialog.selected != nil and dialog.selected != ""
        metric_name.text = dialog.selected
      end   
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Statistic")
    statistic = FXComboBox.new(frame1, 5, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    statistic.numVisible = 5
    statistic.appendItem("Average");
    statistic.appendItem("Maximum");
    statistic.appendItem("Minimum");
    statistic.appendItem("SampleCount");
    statistic.appendItem("Sum");
    statistic.connect(SEL_COMMAND) do |sender, sel, data|
      statistic_value = data
    end    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Period (Secs)")
    period = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Threshold")
    threshold = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Comparison Operator")
    comparison_operator = FXComboBox.new(frame1, 5, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    comparison_operator.numVisible = 4
    comparison_operator.appendItem("GreaterThanOrEqualToThreshold");
    comparison_operator.appendItem("GreaterThanThreshold");
    comparison_operator.appendItem("LessThanThreshold");
    comparison_operator.appendItem("LessThanOrEqualToThreshold");
    comparison_operator.connect(SEL_COMMAND) do |sender, sel, data|
      comparison_operator_value = data
    end	    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Dimensions")
    frame1d = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    dimensions = FXTextField.new(frame1d, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1d, "       use Name=Value" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Evaluation Periods")
    evaluation_periods = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Unit")
    frame1c = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    unit = FXTextField.new(frame1c, 20, nil, 0, :opts => FRAME_SUNKEN)
    unit_button = FXButton.new(frame1c, "", :opts => BUTTON_TOOLBAR)
    unit_button.icon = @magnifier
    unit_button.tipText = "Select Unit"
    unit_button.connect(SEL_COMMAND) do
      dialog = AS_UnitDialog.new(@ec2_main)
      dialog.execute
      if dialog.selected != nil and dialog.selected != ""
        unit.text = dialog.selected
      end   
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Actions Enabled")
    actions_enabled = FXComboBox.new(frame1, 5, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    actions_enabled.numVisible = 2
    actions_enabled.appendItem("True");
    actions_enabled.appendItem("False");
    actions_enabled.connect(SEL_COMMAND) do |sender, sel, data|
      actions_enabled_value = data
    end	        
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Alarm Actions")
    alarm_actions = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    alarm_actions_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    alarm_actions_button.icon = @magnifier
    alarm_actions_button.tipText = "Select Action"
    alarm_actions_button.connect(SEL_COMMAND) do
      dialog = AS_PolicyDialog.new(@ec2_main)
      dialog.execute
      if dialog.selected != nil and dialog.selected != ""
        alarm_actions.text = dialog.selected
      end   
    end
    FXLabel.new(frame1, "Insufficient Data Actions")
    insufficient_data_actions = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "OK Actions")
    ok_actions = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )

    FXLabel.new(frame1, "Alarm Configuration Updated")
    alarm_configuration_updated_timestamp = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "State Reason")
    state_reason = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "State Reason Data")
    state_reason_data = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "State Updated")
    state_updated_timestamp = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "State Value")
    state_value = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Alarm Arn")
    alarm_arn = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X|BUTTON_INITIAL)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      if alarm_name.text == nil or alarm_name.text == ""
        error_message("Error","Alarm Name not specified")
      else
        r = {}
        r['AlarmName'] = alarm_name.text      
        r['AlarmDescription'] = alarm_description.text                      
        r['ComparisonOperator'] = comparison_operator_value
        dim = (dimensions.text).split(",")
        dim_ah = []
        dim.each do |a|
          b = a.split('=')
          if b.size>0 
            dim_ah.push({ 'Name' => b[0], 'Value' => b[1]})
          end
        end           
        r['Dimensions'] = dim_ah                    
        r['EvaluationPeriods'] = (evaluation_periods.text).to_i
        r['InsufficientDataActions'] = (insufficient_data_actions.text).split(",")
        r['MetricName'] = metric_name.text
        r['Statistic'] = statistic_value
        r['Namespace'] = namespace.text
        r['OKActions'] = (ok_actions.text).split(",")      
        r['Period'] = (period.text).to_i
        if actions_enabled_value == "True"
          r['ActionsEnabled']   = true 
        else
          r['ActionsEnabled']   = false 
        end
        r['AlarmActions'] =  (alarm_actions.text).split(',')
        r['Statistic'] = statistic_value
        r['Threshold'] = (threshold.text).to_i
        r['Unit'] = unit.text         
        #r['AlarmConfigurationUpdatedTimestamp'] = alarm_configuration_updated_timestamp.text
        #r['StateReason'] = state_reason.text
        #r['StateReasonData'] = state_reason_data.text                    
        #r['StateUpdatedTimestamp'] = state_updated_timestamp.text
        #r['StateValue'] = state_value.text
        #r['AlarmArn'] = alarm_arn.text               
        put_metric_alarm(r)
        if @saved == true
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end         
      end  
    end
    if @result != ""
      #as.describe_triggers(@as_name).each do |r|
      options = {}
      options['PolicyNames.member.1']= @result
      @ec2_main.environment.cloud_watch.describe_alarms().each do |r|
        if r['AlarmName'] == @result
          alarm_name.text = r['AlarmName']  
          alarm_description.text = r['AlarmDescription']                     
          comparison_operator_value = r['ComparisonOperator']
          comparison_operator.setCurrentItem(0)
          if comparison_operator_value == "GreaterThanThreshold"
            comparison_operator.setCurrentItem(1)
          end
          if comparison_operator_value == "LessThanThreshold"
            comparison_operator.setCurrentItem(2)
          end
          if comparison_operator_value == "LessThanOrEqualToThreshold"
            comparison_operator.setCurrentItem(3)
          end
          dim = ""	
          if r['Dimensions'] != nil 
            r['Dimensions'].each do |d|
              if dim == ""
                dim = "#{d['Name']}=#{d['Value']}"
              else
                dim = dim+",#{d['Name']}=#{d['Value']}"
              end   
            end
          end   
          dimensions.text = dim                   
          evaluation_periods.text = r['EvaluationPeriods'].to_s
          insufficient_data_actions.text = r['InsufficientDataActions']
          metric_name.text = r['MetricName']
          namespace.text = r['Namespace']
          ok_actions.text = r['OKActions']      
          period.text = r['Period'].to_s
          if r['ActionsEnabled'] == "true"
            actions_enabled.setCurrentItem(0)
            actions_enabled_value = "True"
          else
            actions_enabled.setCurrentItem(1)
            actions_enabled_value = "False"                     
          end
          alarm_actions.text = r['AlarmActions']
          statistic_value = r['Statistic']
          case statistic_value
          when "Average"
            statistic.setCurrentItem(0)
          when "Maximum"
            statistic.setCurrentItem(1)
          when "Minimum"
            statistic.setCurrentItem(2)
          when "SampleCount"
            statistic.setCurrentItem(3)
          when "Sum"
            statistic.setCurrentItem(4)
          end
          threshold.text = r['Threshold'].to_s
          unit.text = r['Unit']
          alarm_configuration_updated_timestamp.text = r['AlarmConfigurationUpdatedTimestamp'].to_s                     
          alarm_arn.text = r['AlarmArn']
          state_reason.text = r['StateReason']
          state_reason_data.text = r['StateReasonData']                    
          state_updated_timestamp.text = r['StateUpdatedTimestamp'].to_s
          state_value.text = r['StateValue']
        end
      end
    else
      namespace.text = "AWS/EC2"
      unit.text = "Percent"
      metric_name.text = "CPUUtilization"
      evaluation_periods.text = "1"
      statistic_value = "Average"
      actions_enabled_value = "True"
      comparison_operator_value = "GreaterThanOrEqualToThreshold"
    end
  end 
  def put_metric_alarm(options)
    begin
      puts "options #{options}" 
      r = @ec2_main.environment.cloud_watch.put_metric_alarm(options)
      @saved = true
    rescue
      error_message("Create or Update Alarm Failed",$!)
    end 
  end 

  def saved
    @saved
  end
  def success
    @saved
  end
end
