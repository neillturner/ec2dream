
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_BlockMappingEditDialog < FXDialogBox

  def initialize(owner,bmap)
    puts "ASBlockMappingEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if bmap == nil 
       @bm = {}
       @title = "Add Block Device"
    else
       @bm = bmap
       @title = "Edit Block Device"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 350, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Device Name" )
    device_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    device_name.enabled = true
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "Virtual Name" )
    virtual_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    virtual_name.enabled = true
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       if device_name.text != "" and virtual_name.text != ""
          @bm[:device_name] = device_name.text
          @bm[:virtual_name] = virtual_name.text
          @saved = true
       end   
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @bm != nil
       device_name.text = @bm[:device_name]
       virtual_name.text = @bm[:virtual_name]
    end   
  end
  
  def saved
    @saved
  end
  
  def block_mapping
     @bm
  end   
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
