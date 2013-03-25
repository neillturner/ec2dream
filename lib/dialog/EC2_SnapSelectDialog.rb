require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_SnapSelectDialog < FXDialogBox

  def initialize(owner, snap_owner_id)
    puts "SnapSelectDialog.initialize"
    @ec2_main = owner
    @selected = false
    super(owner, "Snapshot Owner", :opts => DECOR_ALL, :width => 350, :height => 120)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    radio1 = FXRadioButton.new(frame1a, "self")
    radio2 = FXRadioButton.new(frame1a, "amazon")
    radio3 = FXRadioButton.new(frame1a, "AWS Account ID")
    FXLabel.new(frame1, "" )
    case snap_owner_id
      when "self"
        radio1.checkState = true
        radio2.checkState = false
        radio3.checkState = false
      when "amazon"
        radio1.checkState = false
        radio2.checkState = true
        radio3.checkState = false
      else
        radio1.checkState = false
        radio2.checkState = false
        radio3.checkState = true
    end    
    FXLabel.new(frame1, "Snapshot Owner" )
    @snap_owner = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @snap_owner.text = snap_owner_id
    FXLabel.new(frame1, "" )
    radio1.connect(SEL_COMMAND) {
       @snap_owner.text = "self"
       radio2.checkState = false
       radio3.checkState = false
    }
    radio2.connect(SEL_COMMAND) {
       @snap_owner.text = "amazon"
       radio1.checkState = false
       radio3.checkState = false
    }
    radio3.connect(SEL_COMMAND) { 
          @snap_owner.text = ""
          radio1.checkState = false
          radio2.checkState = false
    }    
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
        @selected = true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def snap_owner
    return @snap_owner.text
  end  
  
  def restorable_by
     return nil
  end 
  
  def selected
     @selected
  end  

end
