require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_CSVDialog < FXDialogBox

  def initialize(owner, csv_text, type)
    puts "CSVDialog.initialize"
    @ec2_main = owner
    super(owner, "CSV - "+type, :opts => DECOR_ALL, :width => 700, :height => 375)
    frame1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    @text_area = FXText.new(frame1, :opts => TEXT_WORDWRAP|LAYOUT_FILL)
    @text_area.text = csv_text
    cancel = FXButton.new(frame1, "   &Cancel   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 

end