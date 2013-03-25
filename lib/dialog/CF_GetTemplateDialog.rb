
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class CF_GetTemplateDialog < FXDialogBox

  def initialize(owner, stack_name)
    puts "CF_GetTemplateDialog.initialize"
    @ec2_main = owner
    super(owner, "Template for stack #{stack_name}", :opts => DECOR_ALL, :width => 800, :height => 500)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    text_area = FXText.new(page1, :opts => TEXT_WORDWRAP|LAYOUT_FILL)
    text = ""
     cf = @ec2_main.environment.cf_connection
     if cf != nil
	begin
           response = cf.get_template(stack_name) 
            if response.status == 200
	       text = response.body["TemplateBody"]
	    else   
	       text = ""
	    end                  
         rescue
            puts "ERROR: getting template  #{$!}"
         end           
     end
    text_area.setText(text)
    FXLabel.new(page1, "" )
    close = FXButton.new(page1, "   &Close   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(page1, "" )
    close.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 
  
  def success
    @false
  end  
  
end
