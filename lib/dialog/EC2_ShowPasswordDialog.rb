require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_ShowPasswordDialog < FXDialogBox

  def initialize(owner,title,item)
    puts "EC2_ShowPasswordDialog.initialize"
    @ec2_main = owner
    @title = title
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 550, :height => 50)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, @title )
    value = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    if item != nil
        value.text = item
    end   
  end
 
end
