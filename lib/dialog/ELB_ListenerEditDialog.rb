
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class ELB_ListenerEditDialog < FXDialogBox

  def initialize(owner,item)
    puts "ELBListenerEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if item == nil 
       @result = {}
       @title = "Add Listener"
    else
       @result = item
       @title = "Edit Listener"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 350, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Protocol" )
    protocol = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    protocol.numVisible = 2      
    protocol.appendItem("HTTP")	
    protocol.appendItem("TCP")
    protocol.setCurrentItem(0)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "Load Balancer Port" )
    load_balancer_port = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Instance Port" )
    instance_port = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       if protocol.itemCurrent?(1)
          @result[:protocol] = "TCP"
       else
          @result[:protocol] = "HTTP"
       end
       @result[:load_balancer_port] = load_balancer_port.text
       @result[:instance_port] = instance_port.text
       @saved = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @result != nil
       if @result[:protocol] != nil
          if (@result[:protocol]).upcase == "HTTP"
      	     protocol.setCurrentItem(0)
          end
          if (@result[:protocol]).upcase == "TCP"
             protocol.setCurrentItem(1)
          end
       end   
       load_balancer_port.text = @result[:load_balancer_port]
       instance_port.text = @result[:instance_port]
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
