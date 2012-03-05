
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_TriggerDimensionEditDialog < FXDialogBox

  def initialize(owner,item)
    puts "ASTriggerDimensionEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
       @result = {}
       @title = "Add Trigger Dimension"
    else
       @result = item
       @title = "Edit Trigger Dimension"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 350, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key" )
    key = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Value" )
    value = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       @result[:key] = key.text
       @result[:value] = value.text
       @saved = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @result != nil
       key.text = @result[:key]
       value.text = @result[:value]
    end   
  end
  
  def saved
    @saved
  end
  
  def result
    @result
  end   
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
