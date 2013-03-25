
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_CapacityDialog < FXDialogBox

  def initialize(owner, as_group, capacity)
    @ec2_main = owner
    @as_name =  as_group
    @updated = false
    super(owner, "Set Desired Capacity - #{@as_name}", :opts => DECOR_ALL, :width => 400, :height => 100)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Desired Capacity for #{@as_name}" )
    desired_capacity = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    desired_capacity.text = capacity
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    update = FXButton.new(frame2, "   &Update   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data|
	  begin 
             #as.set_desired_capacity(@as_name, desired_capacity.text )
             @ec2_main.environment.auto_scaling_groups.set_desired_capacity(@as_name, desired_capacity.text )
          rescue
             error_message("Set Desired Capacity Failed",$!)
          end             
          @updated = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end  
   
  def updated
     @updated
  end
 
  def saved
      @updated
  end
  
  def success
     @updated
  end
 
end