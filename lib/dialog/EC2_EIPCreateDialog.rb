require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_EIPCreateDialog < FXDialogBox

  def initialize(owner)
    puts "EIPDialog.initialize"
    @ec2_main = owner
    @curr_env = ""
    @created = false
    @type = nil
    @ec2_platform = @ec2_main.settings.get('EC2_PLATFORM')

    super(owner, "Create IP Address", :opts => DECOR_ALL, :width => 240, :height => 90)    
     
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    if @ec2_main.settings.amazon
       FXLabel.new(frame1, "Domain" )
       frame2 = FXHorizontalFrame.new(frame1,LAYOUT_CENTER_X, :padding => 0)
       @radio1 = FXRadioButton.new(frame2, "Standard")
       @radio1.connect(SEL_COMMAND) {
          @type = "standard"
          @radio2.checkState = false
       }
       @radio2 = FXRadioButton.new(frame2, "VPC")
       @radio2.connect(SEL_COMMAND) {
          @type = "vpc"
          @radio1.checkState = false
       }
       @radio1.checkState = true
    end
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Allocate   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )    
    create.connect(SEL_COMMAND) do |sender, sel, data|
       create_address(@type)
       if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end 
  
  def create_address(type)
     puts "allocate #{type} address"
     begin 
        @ec2_main.environment.addresses.allocate(type)
        @created = true
     rescue
     	error_message("Allocate IP Address failed",$!)
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
