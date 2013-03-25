require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'common/browser'

include Fox

class AS_ScheduledActionEditDialog < FXDialogBox

  def initialize(owner, item=nil, group="")
    puts "AS_ScheduledActionEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
       @result = ""
       @as_group = group
       @title = "Add Scheduled Action"
    else
       @as_group = group
       @result = item
       @title = "Edit Scheduled Action"
    end
    @saved = false
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(owner, @title, :opts => DECOR_ALL, :width => 600, :height => 300)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Auto Scaling Group" )
    group_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    group_name.text = @as_group
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Scheduled Action Name")
    scheduled_action_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Start Time (ISO8601 Format)")
    start_time = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "End Time (ISO8601 Format)")
    end_time = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Recurrence (Cron Format}")
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    recurrence = FXTextField.new(frame1a, 40, nil, 0, :opts => FRAME_SUNKEN)
    recurrence_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    recurrence_button.icon = @magnifier
    recurrence_button.tipText = "Select Namespace"
    recurrence_button.connect(SEL_COMMAND) do
       browser("http://en.wikipedia.org/wiki/Cron")
    end    
    FXLabel.new(frame1, "" )     
    FXLabel.new(frame1, "DesiredCapacity")
    desired_capacity = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "MinSize")
    min_size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "MaxSize")
    max_size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "ScheduledAction Arn")
    scheduled_action_arn = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       if scheduled_action_name.text == nil or scheduled_action_name.text == ""
         error_message("Error","Scheduled Action Name not specified")
       else
         r = {}
         if start_time.text != nil and start_time.text != ""
            r['StartTime'] = start_time.text
         end
         if end_time.text != nil and end_time.text != ""
            r['EndTime'] = end_time.text
         end 
         if desired_capacity.text != nil and desired_capacity.text != ""
            r['DesiredCapacity'] = (desired_capacity.text).to_i
         end
         if min_size.text != nil and min_size.text != ""
            r['MinSize'] = (min_size.text).to_i
         end   
         if max_size.text != nil and max_size.text != ""
            r['MaxSize'] = (max_size.text).to_i
         end   
         if recurrence.text != nil and recurrence.text != ""
            r['Recurrence'] = recurrence.text
         end
         put_scheduled_update_group_action(group_name.text, scheduled_action_name.text, nil, r)
         if @saved == true
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end         
       end  
    end
    if @result != ""
          options = {}
          options['AutoScalingGroupName']= group_name.text
          options['ScheduledActionNames']= [@result]
          @ec2_main.environment.scheduled_actions.all(options).each do |r|
             if r['ScheduledActionName'] = @result
                     scheduled_action_name.text = r['ScheduledActionName']
                     if r['StartTime'] != nil
                        start_time.text = r['StartTime'].iso8601
                     end
                     if r['EndTime'] != nil
                        end_time.text = r['EndTime'].iso8601
                     end   
                     desired_capacity.text = r['DesiredCapacity'].to_s                   
                     min_size.text = r['MinSize'].to_s
                     max_size.text = r['MaxSize'].to_s
                     recurrence.text = r['Recurrence'].to_s
                     scheduled_action_arn.text = r['ScheduledActionARN']
                  end
          end
     else
      start_time.text = "YYYY-MM-DDT00:00:00Z"
     end
  end 
  
  def put_scheduled_update_group_action(auto_scaling_group_name, scheduled_action_name, time=nil, options = {}) 
      begin
       puts "options #{options}" 
       r = @ec2_main.environment.scheduled_actions.put_scheduled_update_group_action(auto_scaling_group_name, scheduled_action_name, time, options ) 
       @saved = true
      rescue
        error_message("Create or Update Scheduled Action Failed",$!)
      end 
  end 

    def saved
     @saved
  end
  
  def success
     @saved
  end

end
