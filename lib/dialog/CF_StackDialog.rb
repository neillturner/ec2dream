require 'rubygems'
require 'fox16'

include Fox

class CF_StackDialog < FXDialogBox

  def initialize(owner)
    puts " CF_StackDialog.initialize"
    @saved = false
    @ec2_main = owner
    @stack_name = ""
    super(@ec2_main, "Cloud Formation Stack Name", :opts => DECOR_ALL, :width => 400, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Stack Name" )
    stack_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    select = FXButton.new(frame1, "   &Select   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    select.connect(SEL_COMMAND) do |sender, sel, data|
       if stack_name.text != nil or stack_name.text != ""
         @stack_name = stack_name.text
       end         
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 
  
  def stack_name
    @stack_name
  end
  
end
