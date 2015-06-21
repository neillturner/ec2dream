require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class ELB_ListenerEditDialog < FXDialogBox

  def initialize(owner, load_balancer, item)
    puts "ELBListenerEditDialog.initialize"
    @ec2_main = owner
    @lb_name = load_balancer 
    @title = ""
    if item == nil 
      @result = {}
      @title = "Add Listener"
    else
      @result = item
      @title = "Edit Listener"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 400, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Protocol" )
    protocol = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    protocol.numVisible = 4      
    protocol.appendItem("HTTP")
    protocol.appendItem("HTTPS")
    protocol.appendItem("TCP")
    protocol.appendItem("SSL")
    protocol.setCurrentItem(0)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "Load Balancer Port" )
    load_balancer_port = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Instance Port" )
    instance_port = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Instance Protocol" )
    instance_protocol = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    instance_protocol.numVisible = 4      
    instance_protocol.appendItem("HTTP")
    instance_protocol.appendItem("HTTPS")
    instance_protocol.appendItem("TCP")
    instance_protocol.appendItem("SSL")
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSL Certificate Id" )
    ssl_certificate_id = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      if protocol.itemCurrent?(0)
        @result['Protocol'] = "HTTP"
      elsif protocol.itemCurrent?(1)
        @result['Protocol'] = "HTTPS"
      elsif protocol.itemCurrent?(2)
        @result['Protocol'] = "TCP"          
      elsif protocol.itemCurrent?(3)
        @result['Protocol'] = "SSL"         
      end
      @result['LoadBalancerPort'] = load_balancer_port.text
      @result['InstancePort'] = instance_port.text
      if instance_protocol.itemCurrent?(0)
        @result['InstanceProtocol'] = "HTTP"
      elsif instance_protocol.itemCurrent?(1)
        @result['InstanceProtocol'] = "HTTPS"
      elsif instance_protocol.itemCurrent?(2)
        @result['InstanceProtocol'] = "TCP"          
      elsif instance_protocol.itemCurrent?(3)
        @result['InstanceProtocol'] = "SSL"         
      end       
      @result['SSLCertificateId'] = ssl_certificate_id.text
      @saved = true
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @result['Protocol'] != nil and @result['Protocol'] != ""
      if @result['Protocol'] = "HTTP"
        instance_protocol.setCurrentItem(0)
      elsif @result['Protocol'] = "HTTPS"
        instance_protocol.setCurrentItem(1)
      elsif @result['Protocol'] = "TCP"
        instance_protocol.setCurrentItem(2)
      elsif @result['Protocol'] = "SSL"
        instance_protocol.setCurrentItem(3)          
      end
    else 
      instance_protocol.setCurrentItem(0)
    end    
    if @result['LoadBalancerPort'] != nil 
      load_balancer_port.text = @result['LoadBalancerPort']
    end    
    if @result['InstancePort'] != nil 
      instance_port.text = @result['InstancePort']
    end    
    if @result['SSLCertificateId'] != nil 
      ssl_certificate_id.text = @result['SSLCertificateId']
    end
  end   
  def saved
    @saved
  end
  def success
    @saved
  end
  def result
    @result
  end   

end
