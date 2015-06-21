
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_System_ConsoleDialog < FXDialogBox

  def initialize(owner, group, instance)
    puts "System_ConsoleDialog.initialize"
    @ec2_main = owner
    super(owner, "System Console "+group+"/"+instance, :opts => DECOR_ALL, :width => 800, :height => 500)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    text_area = FXText.new(page1, :opts => TEXT_WORDWRAP|LAYOUT_FILL)
    text = ""
    begin
      r = @ec2_main.environment.servers.get_console_output(instance)
      text = r[:aws_output]
    rescue
      text = ""
    end    
    text_area.setText(text)
    FXLabel.new(page1, "" )
    close = FXButton.new(page1, "   &Close   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(page1, "" )
    close.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 

end
