
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_InstanceRebootDialog < FXDialogBox

  def initialize(owner, instance_id)
    puts "InstanceRebootDialog.initialize"
    @ec2_main = owner
    type = "SOFT"
    @created = false
    super(owner, "Reboot Instance "+instance_id, :opts => DECOR_ALL, :width => 275, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Type" )
    itemlist = FXComboBox.new(frame1, 20,
    :opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    itemlist.appendItem('SOFT')
    itemlist.appendItem('HARD')
    itemlist.numVisible = 2
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      type = data
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Reboot   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      begin
        r = @ec2_main.environment.servers.reboot_server(instance_id,type)
        @created = true
      rescue
        error_message("Reboot Instance Failed",$!)
      end
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end
  def saved
    @created
  end
  def rebooted
    @created
  end

  def success
    @created
  end
end