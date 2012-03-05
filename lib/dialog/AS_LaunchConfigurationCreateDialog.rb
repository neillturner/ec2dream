require 'rubygems'
require 'fox16'

class AS_LaunchConfigurationCreateDialog < FXDialogBox

 def initialize(owner)
    puts "ASLaunchConfigurationCreateDialog.initialize"
    @ec2_main = owner
    @selected_item = ""
    super(owner, "Create Launch Configuration", :opts => DECOR_ALL, :width => 300, :height => 90)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Launch Configuration" )
    item = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    item.text = ""
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Select   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if item.text != nil and item.text != ""
	  @selected_item = item.text 
       end
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
 end
 
 def selected 
     @selected_item 
 end
 
end 
