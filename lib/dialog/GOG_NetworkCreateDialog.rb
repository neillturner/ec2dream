require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_NetworkCreateDialog < FXDialogBox

  def initialize(owner)
    puts "NetworkCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    super(owner, "Create Network", :opts => DECOR_ALL, :width => 700, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Network Name" )
    name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "IP Address Range (CIDR Format)" )
	ip_address_range = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
	ip_address_range.text = "10.0.0.0/8" 
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if name.text == nil or name.text == ""
         error_message("Error","Network Name not specified")
       else
         create_network(name.text, ip_address_range.text)
		 self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil) if @created == true
       end  
    end
    cancel = FXButton.new(frame2, "   &Cancel   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
  end 
  
  def create_network(name, ip_address_range)
      begin 
       r = @ec2_main.environment.vpc.insert_network(name, ip_address_range)
       @created = true
      rescue
        error_message("Create Network Failed",$!)
      end 
  end 
  
  def saved
     @created
  end
  
  def created
     @created
  end
  
  def success
     @created
  end

end
