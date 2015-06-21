require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class GOG_FirewallMappingEditDialog < FXDialogBox

  def initialize(owner,fmap)
    puts "FirewallMappingEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if fmap == nil 
      @fm = {}
      @title = "Add Firewall Rule"
    else
      @fm = fmap
      @title = "Edit Firewall Rule"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 400, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "IPProtocol" )
    ip_protocol = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "ports" )
    ports = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      @fm['IPProtocol'] = ip_protocol.text
      @fm['ports'] = ports.text
      @saved = true
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @fm != nil
      ip_protocol.text = @fm['IPProtocol']
      ports.text = @fm['ports']
    end   
  end
  def saved
    @saved
  end
  def firewall_mapping
    @fm
  end   

end
